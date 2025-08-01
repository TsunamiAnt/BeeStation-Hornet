//shuttle mode defines
#define SHUTTLE_IDLE		"idle"
#define SHUTTLE_IGNITING	"igniting"
#define SHUTTLE_RECALL		"recalled"
#define SHUTTLE_CALL		"called"
#define SHUTTLE_DOCKED		"docked"
#define SHUTTLE_STRANDED	"stranded"
#define SHUTTLE_ESCAPE		"escape"
#define SHUTTLE_ENDGAME		"endgame: game over"
#define SHUTTLE_RECHARGING		"recharging"
#define SHUTTLE_PREARRIVAL		"landing"

#define EMERGENCY_CALLED (SSshuttle.emergency && SSshuttle.emergency.mode == SHUTTLE_CALL)
#define EMERGENCY_IDLE_OR_RECALLED (SSshuttle.emergency && ((SSshuttle.emergency.mode == SHUTTLE_IDLE) || (SSshuttle.emergency.mode == SHUTTLE_RECALL)))
#define EMERGENCY_ESCAPED_OR_ENDGAMED (SSshuttle.emergency && ((SSshuttle.emergency.mode == SHUTTLE_ESCAPE) || (SSshuttle.emergency.mode == SHUTTLE_ENDGAME)))
#define EMERGENCY_AT_LEAST_DOCKED (SSshuttle.emergency && SSshuttle.emergency.mode != SHUTTLE_IDLE && SSshuttle.emergency.mode != SHUTTLE_RECALL && SSshuttle.emergency.mode != SHUTTLE_CALL)

// Shuttle return values
#define SHUTTLE_CAN_DOCK "can_dock"
#define SHUTTLE_NOT_A_DOCKING_PORT "not a docking port"
#define SHUTTLE_DWIDTH_TOO_LARGE "docking width too large"
#define SHUTTLE_WIDTH_TOO_LARGE "width too large"
#define SHUTTLE_DHEIGHT_TOO_LARGE "docking height too large"
#define SHUTTLE_HEIGHT_TOO_LARGE "height too large"
#define SHUTTLE_ALREADY_DOCKED "we are already docked"
#define SHUTTLE_SOMEONE_ELSE_DOCKED "someone else docked"

//Launching Shuttles to CentCom
#define NOLAUNCH -1
#define UNLAUNCHED 0
#define ENDGAME_LAUNCHED 1
#define EARLY_LAUNCHED 2
#define ENDGAME_TRANSIT 3

// Ripples, effects that signal a shuttle's arrival
#define SHUTTLE_RIPPLE_TIME 100

#define TRANSIT_REQUEST 1
#define TRANSIT_READY 2

#define SHUTTLE_TRANSIT_BORDER 16

#define PARALLAX_LOOP_TIME 25
#define HYPERSPACE_END_TIME 5

#define HYPERSPACE_WARMUP 1
#define HYPERSPACE_LAUNCH 2
#define HYPERSPACE_END 3

#define CALL_SHUTTLE_REASON_LENGTH 12

//Engine related
#define ENGINE_COEFF_MIN 0.5
#define ENGINE_COEFF_MAX 2
#define ENGINE_DEFAULT_MAXSPEED_ENGINES 5

// Alert level related
#define ALERT_COEFF_AUTOEVAC_NORMAL 2.5
#define ALERT_COEFF_GREEN 2
#define ALERT_COEFF_BLUE 1
#define ALERT_COEFF_RED 0.5
#define ALERT_COEFF_AUTOEVAC_CRITICAL 0.4
#define ALERT_COEFF_DELTA 0.25

//Docking error flags
#define DOCKING_SUCCESS				0
#define DOCKING_BLOCKED				(1<<0)
#define DOCKING_IMMOBILIZED			(1<<1)
#define DOCKING_AREA_EMPTY			(1<<2)
#define DOCKING_NULL_DESTINATION	(1<<3)
#define DOCKING_NULL_SOURCE			(1<<4)

//Docking turf movements
#define MOVE_TURF 1
#define MOVE_AREA 2
#define MOVE_CONTENTS 4

//Rotation params
#define ROTATE_DIR 		1
#define ROTATE_SMOOTH 	2
#define ROTATE_OFFSET	4

#define SHUTTLE_DOCKER_LANDING_CLEAR 1
#define SHUTTLE_DOCKER_BLOCKED_BY_HIDDEN_PORT 2
#define SHUTTLE_DOCKER_BLOCKED 3

//Shuttle defaults
#define SHUTTLE_DEFAULT_SHUTTLE_AREA_TYPE /area/shuttle
#define SHUTTLE_DEFAULT_UNDERLYING_AREA /area/space

//Shuttle unlocks
#define SHUTTLE_UNLOCK_BUBBLEGUM "bubblegum"
#define SHUTTLE_UNLOCK_ALIENTECH "abductor"
#define SHUTTLE_UNLOCK_MEDISIM "holodeck"
#define SHUTTLE_UNLOCK_NARNAR "bcult"

//Shuttle preset danger levels

/// Generally safe for station consumption, has everything a typical shuttle needs
#define SHUTTLE_DANGER_SAFE 0
/// Missing key components or has mild elements of danger, but generally won't kill you
#define SHUTTLE_DANGER_SUBPAR 1
/// Possibility for most people on this shuttle to die with little effort
#define SHUTTLE_DANGER_HIGH 2

#define CUSTOM_SHUTTLE_ACCELERATION_SCALE 10
#define CUSTOM_SHUTTLE_MIN_THRUST_TO_WEIGHT 1

#define SHUTTLE_CREATOR_MAX_SIZE CONFIG_GET(number/max_shuttle_size)
#define CUSTOM_SHUTTLE_LIMIT CONFIG_GET(number/max_shuttle_count)
