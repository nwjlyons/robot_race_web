const std = @import("std");
const beam = @import("beam");

const ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const ID_SIZE: usize = 5;

const Role = enum { guest, admin };
const State = enum { setup, counting_down, playing, finished };

const Range = struct {
    first: u64,
    last: u64,
    step: i64,
};

const GameConfig = struct {
    winning_score: u64,
    num_robots: Range,
    countdown: u64,
};

const Robot = struct {
    id: []const u8,
    name: []const u8,
    role: Role,
    score: u64,
};

const PreviousWin = struct {
    id: []const u8,
    wins: u64,
};

const Game = struct {
    id: []const u8,
    winning_score: u64,
    num_robots: Range,
    countdown: u64,
    config: GameConfig,
    robots: []Robot,
    state: State,
    previous_wins: []PreviousWin,
};

const Stats = struct {
    num_games: u64,
};

const JoinResult = union(enum) {
    ok: Game,
    game_in_progress,
    game_full,
};

const LeaderboardRow = struct {
    robot: Robot,
    win_count: u64,
};

const NewRobotArgs = struct {
    name: []const u8,
    role: Role,
};

const NewGameArgs = struct {
    config: GameConfig,
};

const JoinArgs = struct {
    game: Game,
    robot: Robot,
};

const ScorePointArgs = struct {
    game: Game,
    robot_id: []const u8,
};

const AdminArgs = struct {
    game: Game,
    robot_id: []const u8,
};

const GameArgs = struct {
    game: Game,
};

const IncrementNumGamesArgs = struct {
    stats: Stats,
};

pub fn call_nif(function_name: []const u8, args_term: beam.term) !beam.term {
    var arena_state = std.heap.ArenaAllocator.init(beam.allocator);
    defer arena_state.deinit();
    const allocator = arena_state.allocator();

    if (std.mem.eql(u8, function_name, "new_id")) {
        return beam.make(try newId(allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "new_game_id")) {
        return beam.make(try newPrefixedId("g_", allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "new_robot_id")) {
        return beam.make(try newPrefixedId("r_", allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "new_robot")) {
        const args = try beam.get(NewRobotArgs, args_term, .{ .allocator = allocator });
        const robot = try newRobot(args.name, args.role, allocator);
        return beam.make(robot, .{});
    }

    if (std.mem.eql(u8, function_name, "new_stats")) {
        return beam.make(Stats{ .num_games = 0 }, .{});
    }

    if (std.mem.eql(u8, function_name, "increment_num_games")) {
        const args = try beam.get(IncrementNumGamesArgs, args_term, .{ .allocator = allocator });

        var stats = args.stats;
        stats.num_games += 1;

        return beam.make(stats, .{});
    }

    if (std.mem.eql(u8, function_name, "new_game")) {
        const args = try beam.get(NewGameArgs, args_term, .{ .allocator = allocator });
        return beam.make(try newGame(args.config, allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "join")) {
        const args = try beam.get(JoinArgs, args_term, .{ .allocator = allocator });

        switch (try join(args.game, args.robot, allocator)) {
            .ok => |game| return beam.make(.{ .status = .ok, .game = game }, .{}),
            .game_in_progress => return beam.make(.{ .status = .failed, .reason = .game_in_progress }, .{}),
            .game_full => return beam.make(.{ .status = .failed, .reason = .game_full }, .{}),
        }
    }

    if (std.mem.eql(u8, function_name, "score_point")) {
        const args = try beam.get(ScorePointArgs, args_term, .{ .allocator = allocator });
        return beam.make(try scorePoint(args.game, args.robot_id, allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "robots")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });
        return beam.make(args.game.robots, .{});
    }

    if (std.mem.eql(u8, function_name, "admin")) {
        const args = try beam.get(AdminArgs, args_term, .{ .allocator = allocator });
        return beam.make(admin(args.game, args.robot_id), .{});
    }

    if (std.mem.eql(u8, function_name, "play")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });

        var game = args.game;
        game.state = .playing;

        return beam.make(game, .{});
    }

    if (std.mem.eql(u8, function_name, "countdown")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });
        return beam.make(countdown(args.game), .{});
    }

    if (std.mem.eql(u8, function_name, "score_board")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });
        return beam.make(try scoreBoard(args.game, allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "play_again")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });
        return beam.make(try playAgain(args.game, allocator), .{});
    }

    if (std.mem.eql(u8, function_name, "leaderboard")) {
        const args = try beam.get(GameArgs, args_term, .{ .allocator = allocator });
        return beam.make(try leaderboard(args.game, allocator), .{});
    }

    return error.badarg;
}

fn newId(allocator: std.mem.Allocator) ![]u8 {
    var id = try allocator.alloc(u8, ID_SIZE);

    var random_bytes: [ID_SIZE]u8 = undefined;
    std.crypto.random.bytes(&random_bytes);

    for (random_bytes, 0..) |byte, idx| {
        id[idx] = ALPHABET[@as(usize, byte) % ALPHABET.len];
    }

    return id;
}

fn newPrefixedId(prefix: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const suffix = try newId(allocator);
    var id = try allocator.alloc(u8, prefix.len + suffix.len);

    for (prefix, 0..) |char, idx| {
        id[idx] = char;
    }

    for (suffix, 0..) |char, idx| {
        id[prefix.len + idx] = char;
    }

    return id;
}

fn newRobot(name: []const u8, role: Role, allocator: std.mem.Allocator) !Robot {
    return Robot{
        .id = try newPrefixedId("r_", allocator),
        .name = name,
        .role = role,
        .score = 0,
    };
}

fn newGame(config: GameConfig, allocator: std.mem.Allocator) !Game {
    return Game{
        .id = try newPrefixedId("g_", allocator),
        .winning_score = config.winning_score,
        .num_robots = config.num_robots,
        .countdown = config.countdown,
        .config = config,
        .robots = try allocator.alloc(Robot, 0),
        .state = .setup,
        .previous_wins = try allocator.alloc(PreviousWin, 0),
    };
}

fn join(game: Game, robot: Robot, allocator: std.mem.Allocator) !JoinResult {
    if (game.state == .counting_down or game.state == .playing or game.state == .finished) {
        return .game_in_progress;
    }

    const max_robots: usize = @intCast(game.num_robots.last);

    if (game.robots.len >= max_robots) {
        return .game_full;
    }

    var updated_game = game;
    var robots = try allocator.alloc(Robot, game.robots.len + 1);

    for (game.robots, 0..) |existing_robot, idx| {
        robots[idx] = existing_robot;
    }

    robots[game.robots.len] = robot;
    updated_game.robots = robots;

    return .{ .ok = updated_game };
}

fn scorePoint(game: Game, robot_id: []const u8, allocator: std.mem.Allocator) !Game {
    if (game.state != .playing) {
        return game;
    }

    var updated_game = game;
    updated_game.robots = try cloneRobots(game.robots, allocator);

    var matched: ?usize = null;

    for (updated_game.robots, 0..) |*robot, idx| {
        if (std.mem.eql(u8, robot.id, robot_id)) {
            robot.score += 1;
            matched = idx;
            break;
        }
    }

    if (matched) |idx| {
        if (updated_game.robots[idx].score >= updated_game.winning_score) {
            updated_game.state = .finished;
        }
    }

    return updated_game;
}

fn admin(game: Game, robot_id: []const u8) ?bool {
    for (game.robots) |robot| {
        if (std.mem.eql(u8, robot.id, robot_id)) {
            return robot.role == .admin;
        }
    }

    return null;
}

fn countdown(game: Game) Game {
    var updated_game = game;

    if (game.state == .setup) {
        updated_game.state = .counting_down;
        return updated_game;
    }

    if (game.countdown > 0) {
        updated_game.state = .counting_down;
        updated_game.countdown = game.countdown - 1;
        return updated_game;
    }

    if (game.countdown == 0) {
        updated_game.state = .playing;
    }

    return updated_game;
}

fn scoreBoard(game: Game, allocator: std.mem.Allocator) ![]Robot {
    const board = try cloneRobots(game.robots, allocator);
    sortRobotsByScoreDesc(board);
    return board;
}

fn playAgain(game: Game, allocator: std.mem.Allocator) !Game {
    const winner_robot = try winner(game, allocator);

    var updated_game = game;
    updated_game.winning_score = game.config.winning_score;
    updated_game.num_robots = game.config.num_robots;
    updated_game.countdown = game.config.countdown;
    updated_game.robots = try cloneRobots(game.robots, allocator);

    for (updated_game.robots) |*robot| {
        robot.score = 0;
    }

    updated_game.state = .setup;
    updated_game.previous_wins = try incrementPreviousWins(game.previous_wins, winner_robot.id, allocator);

    return updated_game;
}

fn leaderboard(game: Game, allocator: std.mem.Allocator) ![]LeaderboardRow {
    const winner_robot = try winner(game, allocator);

    var rows = try allocator.alloc(LeaderboardRow, game.robots.len);

    for (game.robots, 0..) |robot, idx| {
        const previous_win_count = previousWinsCount(game.previous_wins, robot.id);
        const win_count = if (std.mem.eql(u8, robot.id, winner_robot.id)) previous_win_count + 1 else previous_win_count;

        rows[idx] = .{ .robot = robot, .win_count = win_count };
    }

    sortLeaderboardRowsByWinCountDesc(rows);

    return rows;
}

fn winner(game: Game, allocator: std.mem.Allocator) !Robot {
    const board = try scoreBoard(game, allocator);

    if (board.len == 0) {
        return error.empty_game;
    }

    return board[0];
}

fn cloneRobots(robots: []const Robot, allocator: std.mem.Allocator) ![]Robot {
    var cloned = try allocator.alloc(Robot, robots.len);

    for (robots, 0..) |robot, idx| {
        cloned[idx] = robot;
    }

    return cloned;
}

fn incrementPreviousWins(previous_wins: []const PreviousWin, winner_id: []const u8, allocator: std.mem.Allocator) ![]PreviousWin {
    var updated = try allocator.alloc(PreviousWin, previous_wins.len);

    for (previous_wins, 0..) |entry, idx| {
        updated[idx] = entry;
    }

    for (updated) |*entry| {
        if (std.mem.eql(u8, entry.id, winner_id)) {
            entry.wins += 1;
            return updated;
        }
    }

    var expanded = try allocator.alloc(PreviousWin, previous_wins.len + 1);

    for (updated, 0..) |entry, idx| {
        expanded[idx] = entry;
    }

    expanded[previous_wins.len] = .{ .id = winner_id, .wins = 1 };

    return expanded;
}

fn previousWinsCount(previous_wins: []const PreviousWin, robot_id: []const u8) u64 {
    for (previous_wins) |entry| {
        if (std.mem.eql(u8, entry.id, robot_id)) {
            return entry.wins;
        }
    }

    return 0;
}

fn sortRobotsByScoreDesc(robots: []Robot) void {
    var i: usize = 0;

    while (i < robots.len) : (i += 1) {
        var j: usize = i + 1;

        while (j < robots.len) : (j += 1) {
            if (robots[j].score > robots[i].score) {
                std.mem.swap(Robot, &robots[i], &robots[j]);
            }
        }
    }
}

fn sortLeaderboardRowsByWinCountDesc(rows: []LeaderboardRow) void {
    var i: usize = 0;

    while (i < rows.len) : (i += 1) {
        var j: usize = i + 1;

        while (j < rows.len) : (j += 1) {
            if (rows[j].win_count > rows[i].win_count) {
                std.mem.swap(LeaderboardRow, &rows[i], &rows[j]);
            }
        }
    }
}
