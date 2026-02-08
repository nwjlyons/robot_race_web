import robot_race_robot_id

pub type RobotTuple = #(String, String, String, Int)

pub fn new(name: String, role: String) -> RobotTuple {
  #(robot_race_robot_id.new(), name, normalise_role(role), 0)
}

fn normalise_role(role: String) -> String {
  case role {
    "admin" -> "admin"
    _ -> "guest"
  }
}
