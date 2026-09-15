import copy
import json
import os
import secrets
import threading
from datetime import datetime, timezone
from pathlib import Path

ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
ID_SIZE = 5
IN_PROGRESS_STATES = {"counting_down", "playing", "finished"}
DEFAULT_LOG_PATH = Path(__file__).with_name("robot_race_domain.log")
LOG_PATH = Path(os.environ.get("ROBOT_RACE_DOMAIN_LOG_PATH", str(DEFAULT_LOG_PATH)))
LOG_LOCK = threading.Lock()


def _log(event, **fields):
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(timespec="milliseconds"),
        "event": event,
        **fields,
    }

    try:
        with LOG_LOCK:
            with LOG_PATH.open("a", encoding="utf-8") as log_file:
                log_file.write(json.dumps(entry, sort_keys=True))
                log_file.write("\n")
    except Exception:
        # Never fail game operations because of logging.
        pass


def new_id(_args=None):
    return "".join(secrets.choice(ALPHABET) for _ in range(ID_SIZE))


def new_game_id(_args=None):
    return "g_" + new_id()


def new_robot_id(_args=None):
    return "r_" + new_id()


def new_robot(args):
    robot = {
        "id": new_robot_id(),
        "name": args["name"],
        "role": args["role"],
        "score": 0,
    }

    _log("new_robot", robot_id=robot["id"], name=robot["name"], role=robot["role"])
    return robot


def new_stats(_args=None):
    return {"num_games": 0}


def increment_num_games(args):
    stats = copy.deepcopy(args["stats"])
    before = stats["num_games"]
    stats["num_games"] = stats["num_games"] + 1
    _log("increment_num_games", num_games_before=before, num_games_after=stats["num_games"])
    return stats


def new_game(args):
    config = copy.deepcopy(args["config"])

    game = {
        "id": new_game_id(),
        "winning_score": config["winning_score"],
        "num_robots": config["num_robots"],
        "countdown": config["countdown"],
        "config": config,
        "robots": [],
        "state": "setup",
        "previous_wins": {},
    }

    _log(
        "new_game",
        game_id=game["id"],
        winning_score=game["winning_score"],
        countdown=game["countdown"],
        min_robots=game["num_robots"]["first"],
        max_robots=game["num_robots"]["last"],
    )

    return game


def join(args):
    game = copy.deepcopy(args["game"])
    robot = copy.deepcopy(args["robot"])
    before_count = len(game["robots"])

    if game["state"] in IN_PROGRESS_STATES:
        _log(
            "join_rejected",
            game_id=game["id"],
            robot_id=robot["id"],
            robot_name=robot["name"],
            reason="game_in_progress",
            state=game["state"],
            robot_count=before_count,
        )
        return {"status": "error", "error": "game_in_progress"}

    max_robots = game["num_robots"]["last"]
    if len(game["robots"]) >= max_robots:
        _log(
            "join_rejected",
            game_id=game["id"],
            robot_id=robot["id"],
            robot_name=robot["name"],
            reason="game_full",
            state=game["state"],
            robot_count=before_count,
            max_robots=max_robots,
        )
        return {"status": "error", "error": "game_full"}

    game["robots"].append(robot)
    _log(
        "join_ok",
        game_id=game["id"],
        robot_id=robot["id"],
        robot_name=robot["name"],
        robot_count=len(game["robots"]),
    )
    return {"status": "ok", "game": game}


def score_point(args):
    game = copy.deepcopy(args["game"])
    robot_id = args["robot_id"]

    if game["state"] != "playing":
        _log(
            "score_point_ignored",
            game_id=game["id"],
            robot_id=robot_id,
            state=game["state"],
        )
        return game

    updated_robot = None
    before_score = None

    for robot in game["robots"]:
        if robot["id"] == robot_id:
            before_score = robot["score"]
            robot["score"] = robot["score"] + 1
            updated_robot = robot
            break

    if updated_robot is not None and updated_robot["score"] >= game["winning_score"]:
        game["state"] = "finished"

    if updated_robot is None:
        _log(
            "score_point_unknown_robot",
            game_id=game["id"],
            robot_id=robot_id,
            state=game["state"],
        )
    else:
        _log(
            "score_point",
            game_id=game["id"],
            robot_id=robot_id,
            before_score=before_score,
            after_score=updated_robot["score"],
            state=game["state"],
        )

    return game


def robots(args):
    game = args["game"]
    return copy.deepcopy(game["robots"])


def admin(args):
    game = args["game"]
    robot_id = args["robot_id"]

    for robot in game["robots"]:
        if robot["id"] == robot_id:
            return robot["role"] == "admin"

    return None


def play(args):
    game = copy.deepcopy(args["game"])
    before_state = game["state"]
    game["state"] = "playing"
    _log("play", game_id=game["id"], state_before=before_state, state_after=game["state"])
    return game


def countdown(args):
    game = copy.deepcopy(args["game"])
    before_state = game["state"]
    before_countdown = game["countdown"]

    if game["state"] == "setup":
        game["state"] = "counting_down"
        _log(
            "countdown",
            game_id=game["id"],
            state_before=before_state,
            state_after=game["state"],
            countdown_before=before_countdown,
            countdown_after=game["countdown"],
        )
        return game

    if game["countdown"] > 0:
        game["state"] = "counting_down"
        game["countdown"] = game["countdown"] - 1
        _log(
            "countdown",
            game_id=game["id"],
            state_before=before_state,
            state_after=game["state"],
            countdown_before=before_countdown,
            countdown_after=game["countdown"],
        )
        return game

    if game["countdown"] == 0:
        game["state"] = "playing"

    _log(
        "countdown",
        game_id=game["id"],
        state_before=before_state,
        state_after=game["state"],
        countdown_before=before_countdown,
        countdown_after=game["countdown"],
    )

    return game


def score_board(args):
    game = args["game"]
    return sorted(copy.deepcopy(game["robots"]), key=lambda robot: robot["score"], reverse=True)


def winner(args):
    board = score_board({"game": args["game"]})
    if not board:
        raise IndexError("winner called for an empty scoreboard")
    return board[0]


def play_again(args):
    game = copy.deepcopy(args["game"])
    before_state = game["state"]
    winner_robot = winner({"game": game})

    game["winning_score"] = game["config"]["winning_score"]
    game["num_robots"] = copy.deepcopy(game["config"]["num_robots"])
    game["countdown"] = game["config"]["countdown"]
    game["robots"] = [reset_robot_score(robot) for robot in game["robots"]]
    game["state"] = "setup"
    game["previous_wins"] = save_winner(game["previous_wins"], winner_robot["id"])

    _log(
        "play_again",
        game_id=game["id"],
        winner_robot_id=winner_robot["id"],
        state_before=before_state,
        state_after=game["state"],
        countdown_reset=game["countdown"],
        winner_total_wins=game["previous_wins"].get(winner_robot["id"], 0),
    )

    return game


def leaderboard(args):
    game = copy.deepcopy(args["game"])
    current_winner_id = winner({"game": game})["id"]

    leaderboard_rows = []
    for robot in game["robots"]:
        previous_win_count = game["previous_wins"].get(robot["id"], 0)

        if current_winner_id == robot["id"]:
            win_count = previous_win_count + 1
        else:
            win_count = previous_win_count

        leaderboard_rows.append((robot, win_count))

    leaderboard_rows.sort(key=lambda row: row[1], reverse=True)

    return leaderboard_rows


def reset_robot_score(robot):
    updated_robot = copy.deepcopy(robot)
    updated_robot["score"] = 0
    return updated_robot


def save_winner(previous_wins, winner_id):
    updated_previous_wins = copy.deepcopy(previous_wins)
    updated_previous_wins[winner_id] = updated_previous_wins.get(winner_id, 0) + 1
    return updated_previous_wins
