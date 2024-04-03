USE casedb; /* UPDATED 2023-11-21 */

DELETE FROM AllocCurrentRoundUser;
DELETE FROM AllocSpace;
DELETE FROM AllocSubjectSuitableSpace;
DELETE FROM AllocSubject;

DELETE FROM SubjectEquipment;
DELETE FROM SpaceEquipment;

DELETE FROM Equipment;
ALTER TABLE Equipment AUTO_INCREMENT=2001;

DELETE FROM Space;
ALTER TABLE Space AUTO_INCREMENT=1001;

DELETE FROM Building;
ALTER TABLE Building AUTO_INCREMENT=401;

DELETE FROM DepartmentPlanner;

DELETE FROM User;
ALTER TABLE User AUTO_INCREMENT=201;

DELETE FROM Subject;
ALTER TABLE Subject AUTO_INCREMENT=4001;

DELETE FROM AllocRound;
ALTER TABLE AllocRound AUTO_INCREMENT=10001;

DELETE FROM Program;
ALTER TABLE Program AUTO_INCREMENT=3001;

DELETE FROM Department;
ALTER TABLE Department AUTO_INCREMENT=101;

DELETE FROM SpaceType;
ALTER TABLE SpaceType AUTO_INCREMENT=5001;

DELETE FROM GlobalSetting;
ALTER TABLE GlobalSetting AUTO_INCREMENT=1;

DELETE FROM log_event;
DELETE FROM log_list;
DELETE FROM log_type;

/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */
/* -------------------------- END --------------------------- */
/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */

