import gleam/dict
import gleam/int
import gleam/list
import robot_race_game_id

pub type RobotTuple = #(String, String, String, Int)
pub type ConfigTuple = #(Int, Int, Int, Int)
pub type GameTuple = #(
  String,
  Int,
  Int,
  Int,
  Int,
  ConfigTuple,
  List(RobotTuple),
  String,
  dict.Dict(String, Int),
)
pub type LeaderboardEntry = #(RobotTuple, Int)

pub fn new(
  winning_score: Int,
  min_robots: Int,
  max_robots: Int,
  countdown: Int,
) -> GameTuple {
  let config = #(winning_score, min_robots, max_robots, countdown)

  #(
    robot_race_game_id.new(),
    winning_score,
    min_robots,
    max_robots,
    countdown,
    config,
    [],
    "setup",
    dict.new(),
  )
}

pub fn join(game: GameTuple, robot: RobotTuple) -> Result(GameTuple, String) {
  let #(_, _, _, max_robots, _, _, robots, state, _) = game

  case state {
    "counting_down" | "playing" | "finished" -> Error("game_in_progress")
    _ ->
      case list.length(robots) >= max_robots {
        True -> Error("game_full")
        False -> Ok(set_robots(game, list.append(robots, [robot])))
      }
  }
}

pub fn score_point(game: GameTuple, robot_id: String) -> GameTuple {
  let #(_, winning_score, _, _, _, _, robots, state, _) = game

  case state {
    "playing" -> {
      let updated_robots =
        robots
        |> list.map(fn(robot) {
          case robot_id_of(robot) == robot_id {
            True -> increment_robot_score(robot)
            False -> robot
          }
        })

      let updated_game = set_robots(game, updated_robots)

      case find_robot(updated_robots, robot_id) {
        Ok(updated_robot) ->
          case robot_score(updated_robot) >= winning_score {
            True -> set_state(updated_game, "finished")
            False -> updated_game
          }

        Error(_) -> updated_game
      }
    }
    _ -> game
  }
}

pub fn robots(game: GameTuple) -> List(RobotTuple) {
  let #(_, _, _, _, _, _, robots, _, _) = game
  robots
}

pub fn admin(game: GameTuple, robot_id: String) -> Result(Bool, Nil) {
  case find_robot(robots(game), robot_id) {
    Ok(robot) -> Ok(robot_role(robot) == "admin")
    Error(_) -> Error(Nil)
  }
}

pub fn play(game: GameTuple) -> GameTuple {
  set_state(game, "playing")
}

pub fn countdown(game: GameTuple) -> GameTuple {
  let #(_, _, _, _, countdown, _, _, state, _) = game

  case state {
    "setup" -> set_state(game, "counting_down")
    _ ->
      case countdown > 0 {
        True -> game |> set_state("counting_down") |> set_countdown(countdown - 1)
        False -> set_state(game, "playing")
      }
  }
}

pub fn score_board(game: GameTuple) -> List(RobotTuple) {
  robots(game)
  |> list.sort(by: fn(a, b) { int.compare(robot_score(b), with: robot_score(a)) })
}

pub fn winner(game: GameTuple) -> RobotTuple {
  case score_board(game) {
    [first, ..] -> first
    [] -> panic as "No robots in game"
  }
}

pub fn play_again(game: GameTuple) -> GameTuple {
  let #(id, _, _, _, _, config, robots, _, _) = game
  let #(config_winning_score, config_min_robots, config_max_robots, config_countdown) = config

  #(
    id,
    config_winning_score,
    config_min_robots,
    config_max_robots,
    config_countdown,
    config,
    list.map(robots, fn(robot) { set_robot_score(robot, 0) }),
    "setup",
    save_winner(game),
  )
}

pub fn leaderboard(game: GameTuple) -> List(LeaderboardEntry) {
  let current_winner_id = winner(game) |> robot_id_of
  let #(_, _, _, _, _, _, _, _, previous_wins) = game

  robots(game)
  |> list.map(fn(robot) {
    let previous_win_count = get_previous_win_count(previous_wins, robot_id_of(robot))

    let win_count =
      case current_winner_id == robot_id_of(robot) {
        True -> previous_win_count + 1
        False -> previous_win_count
      }

    #(robot, win_count)
  })
  |> list.sort(by: fn(a, b) {
    let #(_, score_a) = a
    let #(_, score_b) = b
    int.compare(score_b, with: score_a)
  })
}

fn set_robots(game: GameTuple, robots: List(RobotTuple)) -> GameTuple {
  let #(id, winning_score, min_robots, max_robots, countdown, config, _, state, previous_wins) =
    game

  #(
    id,
    winning_score,
    min_robots,
    max_robots,
    countdown,
    config,
    robots,
    state,
    previous_wins,
  )
}

fn set_state(game: GameTuple, state: String) -> GameTuple {
  let #(id, winning_score, min_robots, max_robots, countdown, config, robots, _, previous_wins) =
    game

  #(
    id,
    winning_score,
    min_robots,
    max_robots,
    countdown,
    config,
    robots,
    state,
    previous_wins,
  )
}

fn set_countdown(game: GameTuple, countdown: Int) -> GameTuple {
  let #(id, winning_score, min_robots, max_robots, _, config, robots, state, previous_wins) = game

  #(
    id,
    winning_score,
    min_robots,
    max_robots,
    countdown,
    config,
    robots,
    state,
    previous_wins,
  )
}

fn save_winner(game: GameTuple) -> dict.Dict(String, Int) {
  let winner_id = game |> winner |> robot_id_of
  let #(_, _, _, _, _, _, _, _, previous_wins) = game
  let current_score = get_previous_win_count(previous_wins, winner_id)

  dict.insert(previous_wins, winner_id, current_score + 1)
}

fn find_robot(
  robots: List(RobotTuple),
  robot_id_to_find: String,
) -> Result(RobotTuple, Nil) {
  robots
  |> list.find(one_that: fn(robot) { robot_id_of(robot) == robot_id_to_find })
}

fn get_previous_win_count(
  previous_wins: dict.Dict(String, Int),
  robot_id: String,
) -> Int {
  case dict.get(previous_wins, robot_id) {
    Ok(score) -> score
    Error(_) -> 0
  }
}

fn increment_robot_score(robot: RobotTuple) -> RobotTuple {
  let #(id, name, role, score) = robot
  #(id, name, role, score + 1)
}

fn set_robot_score(robot: RobotTuple, score: Int) -> RobotTuple {
  let #(id, name, role, _) = robot
  #(id, name, role, score)
}

fn robot_id_of(robot: RobotTuple) -> String {
  let #(id, _, _, _) = robot
  id
}

fn robot_role(robot: RobotTuple) -> String {
  let #(_, _, role, _) = robot
  role
}

fn robot_score(robot: RobotTuple) -> Int {
  let #(_, _, _, score) = robot
  score
}
