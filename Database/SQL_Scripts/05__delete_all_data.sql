USE `casedb`;

DELETE FROM SubjectEquipment;

DELETE FROM `Subject`;
ALTER TABLE `Subject` AUTO_INCREMENT=4001;

DELETE FROM Program;
ALTER TABLE Program AUTO_INCREMENT=3001;

DELETE FROM SpaceEquipment;

DELETE FROM Equipment;
ALTER TABLE Equipment AUTO_INCREMENT=2001;

DELETE FROM `Space`;
ALTER TABLE `Space` AUTO_INCREMENT=1001;

DELETE FROM Building;
ALTER TABLE Building AUTO_INCREMENT=401;

DELETE FROM Campus;
ALTER TABLE Campus AUTO_INCREMENT=301;

DELETE FROM DepartmentPlanner;

DELETE FROM `User`;
ALTER TABLE `User` AUTO_INCREMENT=201;

DELETE FROM Department;
ALTER TABLE Department AUTO_INCREMENT=101;