USE casedb; /* UPDATED 2023-11-21 */

-- DROP DATABASE IF EXISTS `casedb`;       /* These would not work other than for root or other able to create schemas */
-- CREATE DATABASE IF NOT EXISTS `casedb`; /* These would not work other than for root or other able to create schemas */

DROP TABLE IF EXISTS log_event;
DROP TABLE IF EXISTS log_list;
DROP TABLE IF EXISTS log_type;

DROP TABLE IF EXISTS AllocCurrentRoundUser;
DROP TABLE IF EXISTS AllocSubjectSuitableSpace;
DROP TABLE IF EXISTS AllocSpace;
DROP TABLE IF EXISTS AllocSubject;

DROP TABLE IF EXISTS SubjectEquipment;
DROP TABLE IF EXISTS Subject;
DROP TABLE IF EXISTS AllocRound;
DROP TABLE IF EXISTS Program;

DROP TABLE IF EXISTS SpaceEquipment;
DROP TABLE IF EXISTS Equipment;

DROP TABLE IF EXISTS Space;
DROP TABLE IF EXISTS SpaceType;
DROP TABLE IF EXISTS Building;

DROP TABLE IF EXISTS DepartmentPlanner;
DROP TABLE IF EXISTS User;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS GlobalSetting;

/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */
/* -------------------------- END --------------------------- */
/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */

