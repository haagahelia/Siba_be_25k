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

USE casedb; /* UPDATED 2024-01-24 */

/* --- 01 CREATE TABLES --- */

CREATE TABLE IF NOT EXISTS GlobalSetting (
    id              INTEGER                     NOT NULL AUTO_INCREMENT,
    variable            VARCHAR(255)   UNIQUE       NOT NULL,
    description     VARCHAR(16000)              NOT NULL,
    numberValue     INTEGER,
    textValue       VARCHAR(255),
    booleanValue    BOOLEAN         DEFAULT 0,
    decimalValue    DECIMAL (6,2)   DEFAULT 0,

    PRIMARY KEY (id)
)   ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Department (
    id          INTEGER                 NOT NULL AUTO_INCREMENT,
    name        VARCHAR(255)    UNIQUE  NOT NULL,
    description VARCHAR(16000),

    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=101 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS User (
    id          INTEGER                 NOT NULL AUTO_INCREMENT,
    email       VARCHAR(255)    UNIQUE  NOT NULL,
    password    VARCHAR(255)            NOT NULL,
    isAdmin     BOOLEAN                 NOT NULL DEFAULT 0,
    isPlanner   BOOLEAN                 NOT NULL DEFAULT 0,
    isStatist   BOOLEAN                 NOT NULL DEFAULT 0,

    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=201 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS DepartmentPlanner (
    departmentId    INTEGER     NOT NULL,
    userId          INTEGER     NOT NULL,

    PRIMARY KEY (departmentId, userId),

    CONSTRAINT FOREIGN KEY (departmentId) REFERENCES Department(id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    CONSTRAINT FOREIGN KEY (userId) REFERENCES User(id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Building (
    id          INTEGER                 NOT NULL AUTO_INCREMENT,
    name        VARCHAR(255)    UNIQUE  NOT NULL,
    description VARCHAR(16000),

    PRIMARY KEY (id)

) ENGINE=InnoDB AUTO_INCREMENT=401 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS SpaceType (
    id          INTEGER         NOT NULL AUTO_INCREMENT,
    name        VARCHAR(255)    NOT NULL,
    description VARCHAR(16000),

    PRIMARY KEY(id)

) ENGINE=InnoDB AUTO_INCREMENT=5001 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Space (
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    name            VARCHAR(255)    NOT NULL,
    area            DECIMAL(5,1)    NOT NULL,
    info            VARCHAR(16000),
    personLimit     INTEGER         NOT NULL,
    buildingId      INTEGER         NOT NULL,
    availableFrom   TIME            NOT NULL,
    availableTo     TIME            NOT NULL,
    classesFrom     TIME            NOT NULL,
    classesTo       TIME            NOT NULL,
	inUse			BOOLEAN        DEFAULT 1,
    spaceTypeId     INTEGER         NOT NULL,

    CONSTRAINT AK_UNIQUE_name_in_building UNIQUE(buildingId, name),

    PRIMARY KEY (id),

    CONSTRAINT `FK_space_building`
    	FOREIGN KEY (buildingId) REFERENCES Building(id)
            ON DELETE NO ACTION
            ON UPDATE CASCADE,

    CONSTRAINT `FK_space_spaceType`
    	FOREIGN KEY (spaceTypeId) REFERENCES SpaceType(id)
            ON DELETE NO ACTION
            ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1001 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Equipment (
    id            INTEGER                   NOT NULL AUTO_INCREMENT,
    name          VARCHAR(255)      UNIQUE  NOT NULL,
    isMovable     BOOLEAN                   NOT NULL,
    priority      INTEGER                   NOT NULL DEFAULT 0,
    description   VARCHAR(16000),

    PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2001 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS SpaceEquipment (
    spaceId       INTEGER     NOT NULL,
    equipmentId   INTEGER     NOT NULL,

    PRIMARY KEY(spaceId,equipmentId),

    CONSTRAINT `FK_SpaceEquipment_Equipment`
        FOREIGN KEY (equipmentId) REFERENCES Equipment(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE,
    CONSTRAINT `FK_SpaceEquipment_Space`
        FOREIGN KEY (spaceId) REFERENCES Space(id)
            ON DELETE CASCADE
            ON UPDATE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Program (
  id            INTEGER         NOT NULL AUTO_INCREMENT,
  name          VARCHAR(255)    NOT NULL UNIQUE,

  departmentId  INTEGER         NOT NULL,

  PRIMARY KEY (id),

  CONSTRAINT FOREIGN KEY (departmentId) REFERENCES Department(id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3001 DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS AllocRound (
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    date            TIMESTAMP       NOT NULL DEFAULT current_timestamp(),
    name            VARCHAR(255)    NOT NULL UNIQUE,
    isSeasonAlloc   BOOLEAN         NOT NULL DEFAULT 0,
    userId          INTEGER         NOT NULL,
    description     VARCHAR(16000)  NOT NULL,
    lastModified    TIMESTAMP       NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    lastCalcSuccs   TIMESTAMP       DEFAULT NULL,
    lastCalcFail    TIMESTAMP       DEFAULT NULL,
    isAllocated     BOOLEAN     DEFAULT 0,
    processOn       BOOLEAN     DEFAULT 0,
    abortProcess    BOOLEAN     DEFAULT 0,
    requireReset    BOOLEAN     DEFAULT 0,

    PRIMARY KEY(id),

    CONSTRAINT `FK_AllocRound_User` FOREIGN KEY (userId)
        REFERENCES User(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE

)ENGINE=InnoDB AUTO_INCREMENT=10001 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS Subject (
    id              INTEGER         NOT NULL AUTO_INCREMENT,
    name            VARCHAR(255)    NOT NULL,
    groupSize       INTEGER         NOT NULL,
    groupCount      INTEGER         NOT NULL,
    sessionLength   TIME            NOT NULL,
    sessionCount    INTEGER         NOT NULL,
    area            DECIMAL(5,1)                DEFAULT NULL,
    programId       INTEGER         NOT NULL,
    spaceTypeId     INTEGER,
    allocRoundId    INTEGER         NOT NULL,

    CONSTRAINT AK_Subject_unique_name_in_program UNIQUE (programId, allocRoundId, name),

    PRIMARY KEY (id),

    CONSTRAINT `FK_Subject_Program` FOREIGN KEY (programId)
        REFERENCES Program(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,

    CONSTRAINT `FK_Subject_SpaceType` FOREIGN KEY (SpaceTypeId)
        REFERENCES SpaceType(id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT `FK_Subject_AllocRound` FOREIGN KEY (allocRoundId)
        REFERENCES AllocRound(id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION

) ENGINE=InnoDB AUTO_INCREMENT=4001 DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS SubjectEquipment (
    subjectId      INTEGER     NOT NULL,
    equipmentId    INTEGER     NOT NULL,
    priority       INTEGER     NOT NULL,
    obligatory     BOOLEAN     NOT NULL     DEFAULT 0,

    PRIMARY KEY (subjectId, equipmentId),

    CONSTRAINT `FK_SubjectEquipment_Subject` FOREIGN KEY (subjectId)
                REFERENCES Subject(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `FK_SubjectEquipment_Equipment` FOREIGN KEY (equipmentId)
                REFERENCES Equipment(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


/* CREATE ALLOC TABLES */

CREATE TABLE IF NOT EXISTS AllocSubject (
    allocRoundId    INTEGER     NOT NULL,
    subjectId       INTEGER     NOT NULL,
    isAllocated     BOOLEAN     NOT NULL DEFAULT 0,
    cantAllocate    BOOLEAN     NOT NULL DEFAULT 0,
    priority        INTEGER,
    allocatedDate   TIMESTAMP,

    PRIMARY KEY(allocRoundId, subjectId),

    CONSTRAINT `FK_AllocSubject_Subject` FOREIGN KEY (subjectId)
        REFERENCES Subject(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `FK_AllocSubject_AllocRound` FOREIGN KEY (allocRoundId)
        REFERENCES AllocRound(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB CHARSET=latin1;

CREATE TABLE IF NOT EXISTS AllocSpace (
    allocRoundId    INTEGER     NOT NULL,
    subjectId       INTEGER     NOT NULL,
    spaceId         INTEGER     NOT NULL,
    totalTime       TIME,

    PRIMARY KEY(subjectId, allocRoundId, spaceId),

    CONSTRAINT `FK_AllocSpace_AllocSubject` FOREIGN KEY (allocRoundId,subjectId)
        REFERENCES AllocSubject(allocRoundId, subjectId)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `FK_AllocSpace_Space` FOREIGN KEY (spaceId)
        REFERENCES Space(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS AllocSubjectSuitableSpace (
    allocRoundId    INTEGER     NOT NULL,
    subjectId       INTEGER     NOT NULL,
    spaceId         INTEGER     NOT NULL,
    missingItems    INTEGER,

    PRIMARY KEY(allocRoundId, subjectId, spaceId),

    CONSTRAINT `FK_AllocSubjectSpace_AllocSubject`
        FOREIGN KEY(allocRoundId, subjectId)
        REFERENCES AllocSubject(allocRoundId, subjectId)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `FK_AllocSubjectSpace_Space`
        FOREIGN KEY (spaceId)
        REFERENCES Space(id)
        ON DELETE NO ACTION
        ON UPDATE CASCADE

) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS AllocCurrentRoundUser (
    allocRoundId    INTEGER     NOT NULL,
    userId          INTEGER     NOT NULL,

    PRIMARY KEY(allocRoundId, userId),

    CONSTRAINT `FK_AllocCurrentRoundUser_AllocRound`
        FOREIGN KEY (allocRoundId)
        REFERENCES AllocRound(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT `FK_AllocCurrentRoundUser_User`
        FOREIGN KEY (userId)
        REFERENCES User(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* CREATE LOG TABLES */

CREATE TABLE IF NOT EXISTS log_type (
    id      INTEGER		    NOT NULL    AUTO_INCREMENT,
    name    VARCHAR(255)    NOT NULL    UNIQUE,

    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS log_list (
    id			INTEGER		NOT NULL AUTO_INCREMENT,
    log_type	INTEGER,
    created_at	TIMESTAMP	NOT NULL DEFAULT CURRENT_TIMESTAMP(),

    PRIMARY KEY (id),

    CONSTRAINT FOREIGN KEY (log_type) REFERENCES log_type(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS log_event (
    id              INTEGER         NOT NULL    AUTO_INCREMENT,
    log_id          INTEGER         NOT NULL,
    stage           VARCHAR(255),
    status          VARCHAR(255),
    information 	VARCHAR(16000),
    created_at      TIMESTAMP       NOT NULL    DEFAULT CURRENT_TIMESTAMP(),

    PRIMARY KEY (id),

    CONSTRAINT FOREIGN KEY (log_id) REFERENCES log_list(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */
/* -------------------------- END --------------------------- */
/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */

USE casedb; /* UPDATED 2024-02-26 */

/* INSERTS */
/* --- Insert: GlobalSettings --- */
INSERT INTO GlobalSetting(variable, description, numberValue, textValue) VALUES
    ('highPriority', 'High priority value', 800, NULL),
    ("allocation-debug", "Is the allocation logging on? numberValue : 0 = OFF, 1 = ON", 1, NULL),
    ("items-per-page", "The number of items to display per page in lists. Default is 15.", 15, NULL);

/* --- Insert: Department --- */
INSERT INTO Department(name, description) VALUES
	('Jazz', NULL),
    ('Laulumusiikki', 'Aineryhmän kuvaus'),
    ('Piano, harmonikka, kitara ja kantele', 'Aineryhmän kuvaus'),
    ('Musiikkikasvatus', 'Aineryhmän kuvaus'),
    ('MuTri', 'Aineryhmän kuvaus'),
    ('Vanha musiikki', 'Aineryhmän kuvaus'),
    ('Musiikkiteknologia', 'Aineryhmän kuvaus'),
    ('Musiikinjohtaminen sekä orkesteri- ja kuorotoiminta', 'Aineryhmän kuvaus'),
    ('Taidejohtaminen ja yrittäjyys', 'Aineryhmän kuvaus'),
    ('DocMus', 'Tohtoritason koulutusohjelma'),
    ('Kansanmusiikki ja Global music & GLOMAS', 'Aineryhmän kuvaus'),
    ('Kirkkomusiikki ja urut', 'Aineryhmän kuvaus'),
    ('Jouset ja kamarimusiikki', 'Aineryhmän kuvaus'),
    ('Puhaltimet, lyömäsoittimet ja harppu', 'Aineryhmän kuvaus'),
    ('Sävellys ja musiikinteoria', 'Aineryhmän kuvaus'),
    ('Avoin Kampus', 'Aineryhmän kuvaus');

/* --- Insert: `User` --- */
/* SECURITY: Change these before deployment */
INSERT INTO `User`(email, password, isAdmin, isPlanner, isStatist) VALUES
    ('admin','$2a$10$My5c7qZPRzp2p5QpgzQ0kOt5Au1xdwIidJDegsEWpntwAWceUjdWa',1,0,0),
    ('planner','$2a$10$mKf/VHzIGyIfADKHFACEBuYTb0IbPv6sE/FqlsbLAKgfelMWwsnEm',0,1,0),
    ('statist','$2a$10$3oFjcGMj3Zq.91PkbGuL9Oo1zowAU9WFNNWyYA018Rff5BpCEmQ8y',0,0,1),
    ('noroleuser','$2b$10$J7KRUTRemPc5dYEMnOSTueUKHFFc8T.HwkF7wveUHBj1HzN3yqHRK',0,0,0);

/* --- Insert: DepartmentPlanner * --- */
INSERT INTO DepartmentPlanner(userId, departmentId) VALUES
    (202, 101),
    (202, 105),
    (203, 103),
    (203, 104),
    (202, 102);


/* --- Insert: Building * --- */
INSERT INTO `Building` (`name`, `description`) VALUES
	('Musiikkitalo', NULL),
	('N-talo', 'Sibeliusakatemian opetus ja harjoittelu talo '),
	('R-talo', 'Sibeliusakatemian konserttitalo');

/* --- Insert: SpaceType --- */
INSERT INTO SpaceType (`name`, `description`) VALUES
    ('Studio', NULL),
    ('Luentoluokka','Room for theory classes'),
    ('Esitystila', NULL),
    ('Musiikkiluokka', NULL);

/* --- Insert: `Space` * --- */
INSERT INTO `Space` (`name`, `area`, `personLimit`, `buildingId`, `availableFrom`, `availableTo`, `classesFrom`, `classesTo`, `info`, `spaceTypeId`) VALUES
	('S6117 Jouset/Kontrabasso', 31.9, 7, 401, '08:00:00', '21:00:00', '09:00:00', '16:00:00', 'ONLY FOR BASSISTS', 5004), -- 1001
	('S6104 Didaktiikkaluokka Inkeri', 62.5, 30, 401, '08:00:00', '21:00:00', '10:00:00', '17:00:00', 'Musiikkikasvatus', 5004), -- 1002
	('S7106 Kansanmusiikki/AOV', 63.7, 22, 401, '08:00:00', '21:00:00', '08:00:00', '18:00:00', 'Yhtyeluokka', 5004), -- 1003
    ('S6114 Perkussioluokka/Marimbaluokka', 33.3, 4, 401, '08:00:00', '22:00:00', '09:00:00', '15:00:00', 'Vain lyömäsoittajat', 5004), -- 1004
    ('S1111 Studio Erkki', 36.0, 15, 401, '08:00:00', '22:00:00', '11:00:00', '15:00:00', 'Tilatyyppi: Studio', 5001), -- 1005
    ('S5109 Jazz/Bändiluokka', 17.5, 2, 401, '08:00:00', '20:00:00', '08:00:00', '16:00:00', 'ONLY FOR JAZZ DEPARTMENT', 5004), -- 1006
    ('S6112 Harppuluokka', 28.8, 4, 401, '08:00:00', '17:00:00', '11:00:00', '16:00:00', 'Vain harpistit', 5004), -- 1007
    ('S6113 Puhaltimet/Klarinetti/Harppu', 18.1, 4, 401, '08:00:00', '19:00:00', '08:00:00', '19:00:00', NULL, 5004), -- 1008

    ('R312 Opetusluokka', 16.6, 6, 403, '08:00:00', '21:00:00', '08:00:00', '18:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1009
    ('R530 Opetusluokka', 50.0, 18, 403, '08:00:00', '21:00:00', '08:00:00', '19:00:00', 'Luentoluokka', 5002), -- 1010
    ('R213 Harjoitushuone', 20.0, 4, 403, '08:00:00', '21:00:00', '10:00:00', '16:00:00', 'Ensisijainen varausoikeus vanhan musiikin aineryhmällä', 5004), -- 1011
    ('R510 Opetusluokka', 81.0, 30, 403, '08:00:00', '21:00:00', '09:00:00', '15:00:00', 'Luentoluokka', 5002), -- 1012
    ('R416 Opetusluokka', 23.0, 9, 403, '08:00:00', '21:00:00', '10:00:00', '17:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1013
    ('R422 Opetusluokka', 23.0, 11, 403, '08:00:00', '19:00:00', '08:00:00', '22:00:00', 'Kitara', 5004), -- 1014
    ('R410 Opetusluokka', 42.4, 20, 403, '08:00:00', '19:00:00', '08:00:00', '20:00:00', 'Pianopedagogiikka', 5004), -- 1015
    ('R531 Opetusluokka', 53.0, 17, 403, '09:00:00', '20:00:00', '10:00:00', '14:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1016

    ('N522 Säestysluokka', 33.0, 8, 402, '08:00:00', '21:00:00', '08:00:00', '19:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1017
    ('N319 Jazz/Lyomäsoittimet, piano ja yhtyeet', 34.0, 5, 402, '08:00:00', '19:00:00', '08:00:00', '17:00:00', 'Varaukset Jukkis Uotilan kautta', 5004), -- 1018
    ('N315 Jouset', 15.5, 4, 402, '08:00:00', '21:00:00', '08:00:00', '14:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1019
    ('N419 Kirkkomusiikki/Urkuluokka', 34.0, 5, 402, '09:00:00', '20:00:00', '08:00:00', '18:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1020
    ('N517 Opetusluokka', 15.5, 3, 402, '08:00:00', '21:00:00', '08:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1021
    ('N425 Jouset/Sello', 33.0, 8, 402, '08:00:00', '22:00:00', '09:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1022
    ('N312 Musiikkikasvatus/Vapaasäestys', 34.0, 8, 402, '08:00:00', '22:00:00', '08:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1023
    ('N220 Tohtorikoulut', 49.5, 20, 402, '08:00:00', '19:00:00', '08:00:00', '17:00:00', 'Tilatyyppi: Luentoluokka', 5002), -- 1024

    ('S7109 Kansanmusiikki/Puhallinluokka', 18.5, 4, 401, '8:00:00', '21:00:00', '9:00:00', '18:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1025
    ('S7114 Teorialuokka', 34.2, 12, 401, '9:00:00', '22:00:00', '9:00:00', '17:00:00', 'Tilatyyppi: Luentoluokka', 5002), -- 1026
    ('S4108 Opetusluokka', 28.4, 6, 401, '8:00:00', '21:00:00', '10:00:00', '19:00:00', 'Ensisijainen varaus Kansanmusiikin aineryhmälle', 5002), -- 1027
    ('S5106 Jazz/Yhtyeluokka', 45.1, 17, 401, '10:00:00', '18:00:00', '10:00:00', '16:00:00', 'ONLY FOR JAZZ DEPARTMENT', 5004), -- 1028
    ('R211', 31.2, 11, 403, '8:00:00', '21:00:00', '8:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1029
    ('R212', 33.8, 13, 403, '8:00:00', '21:00:00', '8:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1030
    ('R415', 24.3, 9, 403, '8:00:00', '21:00:00', '8:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1031
    ('R417', 25, 9, 403, '8:00:00', '21:00:00', '8:00:00', '15:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1032
    ('N217', 16, 2, 402, '9:00:00', '21:00:00', '9:00:00', '21:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1033
    ('N310 Puhaltimet/Käyrätorvi', 55.5, 15, 402, '8:00:00', '21:00:00', '9:00:00', '19:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1034
    ('N515 Iso Ryhmäopetusluokka', 70, 25, 402, '8:00:00', '21:00:00', '8:00:00', '21:00:00', 'Tilatyyppi: Musiikkiluokka', 5004), -- 1035
    ('N311 Puhaltimet/Jouset', 34, 8, 402, '8:00:00', '21:00:00', '8:00:00', '21:00:00', 'Tilatyyppi: Musiikkiluokka', 5004); -- 1036


/* --- Insert: Equipment --- */
INSERT INTO `Equipment` (`name`, `isMovable`, `priority`, `description`) VALUES
	('Urut', 0, 600, 'Valtavan kokoinen soitin'), -- 2001
	('Kantele', 1, 50, 'Väinämöisen soitin'), -- 2002
    ('Nokkahuilu', 1, 50, 'Kaikki rakastaa'), -- 2003
    ('Rumpusetti', 1, 250, 'Ääntä riittää'), -- 2004
    ('Äänityslaitteisto Xyz', 0, 900, '8 kanavaa'), -- 2005
    ('Viulu', 1, 50, 'Jousisoitin, 4-kieltä'), -- 2006
    ('Alttoviulu', 1, 50, 'Jousisoitin, suurempi kuin viulu'), -- 2007
    ('Sello', 1, 100, 'Suuri, 4-kielinen jousisoitin'), -- 2008
    ('Kontrabasso', 1, 100, 'Suurin jousisoitin'), -- 2009
    ('Piano', 0, 900, 'Piano-opetus vaatii kaksi flyygeliä'), -- 2010
    ('Kitara', 1, 100, '6-kielinen soitin'), -- 2011
    ('Harmonikka', 1, 200, NULL), -- 2012
    ('Fortepiano', 0, 500, 'Pianon varhaismuoto'), -- 2013
    ('Huilu', 1, 50, 'puhallinsoitin'), -- 2014
    ('Oboe', 1, 100, 'puupuhallinsoitin'), -- 2015
    ('Tuuba', 1, 100, 'Suurehko puhallinsoitin'), -- 2016
    ('Trumpetti', 1, 50, 'Puhallinsoitin'), -- 2017
    ('Clavinova', 1, 100, 'Sähköpiano'), -- 2018
    ('Bassovahvistin', 1, 50, 'Boom boom'), -- 2019
    ('Kitaravahvistin', 1, 50, 'Äänekäs laatikko'), -- 2020
    ('Flyygeli', 1, 200, ''), -- 2021
    ('DVD-soitin', 1, 50, ''), -- 2022
    ('Äänentoisto (ei PA-laitteet)', 0, 100, ''), -- 2023
    ('Näyttölaite (videoprojektori)', 0, 200, ''), -- 2024
    ('Yhtyeluokan äänentoisto', 0, 300, 'PA-laitteet'), -- 2025
    ('Dokumenttikamera', 0, 250, ''), -- 2026
    ('Sähkökitara', 1, 100, 'Sähkökitara'), -- 2027
    ('Käyrätorvi', 1, 100, 'Puhallin'), -- 2028
    ('Cembalo', 0, 900, 'Pianon edeltäjä'); -- 2029

/* --- Insert: SpaceEquipment * --- */
INSERT INTO `SpaceEquipment` (`spaceId`, `equipmentId`) VALUES
	(1001, 2021),
    (1001, 2022),
    (1001, 2023),
    (1001, 2024),
	(1002, 2021),
    (1002, 2004),
    (1002, 2019),
    (1002, 2020),
    (1002, 2022),
    (1002, 2023),
    (1002, 2025),
    (1002, 2024),
    (1002, 2026),
	(1009, 2010),
    (1009, 2021),
    (1009, 2023),
    (1013, 2021),
    (1013, 2023),
    (1020, 2001),
    (1020, 2022),
    (1020, 2023),
    (1020, 2024),
    (1019, 2021),
    (1019, 2022),
    (1019, 2023),
    (1019, 2024),
    (1005, 2010),
    (1005, 2004),
    (1006, 2004),
    (1003, 2004),
    (1004, 2004),
    (1018, 2004),
    (1014, 2011),
    (1006, 2011),
    (1018, 2010),
    (1013, 2010),
    (1025, 2012), -- Harmoni
    (1025, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1026, 2010), -- Piano
    (1026, 2022), -- DVD Soitin
    (1026, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1027, 2010), -- Piano
    (1027, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1027, 2024), -- Näyttölaite
    (1028, 2021), -- Flyygeli
    (1028, 2004), -- Rumpusetti
    (1028, 2020), -- Kitaravahvistin
    (1028, 2019), -- Bassovahvistin
    (1028, 2022), -- DVD-soitin
    (1028, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1028, 2025), -- Yhtyeluokan äänentoisto
    (1029, 2029), -- Cembalo
    (1029, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1030, 2029), -- Cembalo
    (1030, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1031, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1032, 2021), -- Flyygeli
    (1032, 2029), -- Cembalo
    (1032, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1033, 2010), -- Piano
    (1033, 2021), -- Flyygeli
    (1033, 2022), -- DVD-soitin
    (1033, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1033, 2025), -- Yhtyeluokan äänentoisto
    (1033, 2024), -- Näyttölaite
    (1034, 2021), -- Flyygeli
    (1034, 2022), -- DVD-soitin
    (1034, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1035, 2021), -- Flyygeli
    (1035, 2013), -- Fortepiano
    (1035, 2022), -- DVD-soitin
    (1035, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1036, 2021), -- Flyygeli
    (1036, 2022), -- DVD-soitin
    (1036, 2023), -- Äänentoisto (Ei PA-laitteet)
    (1036, 2024), -- Näyttölaite
    (1008, 2003),
    (1008, 2016),
    (1009, 2006),
    (1011, 2010),
    (1011, 2013),
    (1028, 2010),
    (1028, 2011),
    (1029, 2011),
    (1031, 2002),
    (1034, 2017),
    (1003, 2010),
    (1020, 2004),
    (1020, 2010),
    (1011, 2009);

/* --- Insert: Program * --- */
INSERT INTO Program (name , departmentId) VALUES
    ('Piano', 103), -- id 3001
    ('Laulutaide pääaineena', 102),
    ('Kitara', 103),
    ('Kantele', 103),
    ('Jazzsävellys', 101),
    ('Musiikinteoria pääaineena', 104),
    ('Jazzmusiikin instrumentti- tai lauluopinnot pääaineena', 102),
    ('Fortepiano', 103),
    ('Global Music', 112),
    ('Harmonikka', 103),
    ('Harppu', 114),
    ('Jousisoitin', 113),
    ('Kansanmusiikki', 111),
    ('Kirkkomusiikki', 112),
    ('Korrepetitio', 102),
    ('Lyömäsoitin', 114),
    ('Musiikin johtaminen', 108), -- ei löydy kurseja
    ('Musiikin tohtorikoulutus', 110),
    ('Musiikkikasvatus', 104),
    ('Musiikkiteknologia', 107),
    ('Nordic Master in Folk Music', 111),
    ('Nordic Master in Jazz', 101),
    ('Oopperalaulu', 102),
    ('Pianokamarimusiikki ja lied', 103),
    ('Puhallinsoitin', 114),
    ('Sävellys', 115),
    ('Taidejohtaminen ja yrittäjyys', 109),
    ('Urut', 112),
    ('Vanha musiikki', 106),
    ('Avoin Kampus', 110);

/* --- Insert: AllocRound * --- */
INSERT INTO AllocRound(name, isSeasonAlloc, userId, description) VALUES
    ('Testipriorisointi', 0, 201, 'Testidata lisätään AllocSubject tauluun, mutta laskentaa ei vielä suoritettu eli opetuksille ei ole vielä merkitty tiloja'),
    ('Testilaskenta', 1, 201, 'Testidata lisätty ja huoneet merkitty'),
    ('Kevät 2024', 0, 201, 'Official simulation/calculation for Spring 2024'),
    ('Demo', 0, 201, 'Allokointi demoamista varten');

/* --- Insert: Subject * --- */
INSERT INTO Subject(name, groupSize, groupCount, sessionLength, sessionCount, area, programId, spaceTypeId, allocRoundId) VALUES
    ('Saksan kielen perusteet', 20, 2, '01:30:00', 2, 35, 3030, 5002, 10004),
    ('Jazzimprovisoinnin ja -teorian perusteet', 17, 1, '02:30:00', 2, 35, 3005, 5004, 10004),
    ('Piano yksilöopetus', 1, 1, '02:30:00', 2, 10, 3001, 5004, 10004),
    ('Trumpetin ryhmäsoitto', 10, 1,'01:30:00', 3, 40, 3025, 5004, 10004),
    ('Kirkkomusiikin ryhmäsoittoa', 5, 2, '02:30:00', 2, 30, 3014, 5004, 10004),
    ('Ruotsin kielen oppitunti', 18, 2, '01:45:00', 1, 25, 3030, 5002, 10004),
    ('Kitaran soiton perusteet', 11, 1, '01:30:00', 2, 25, 3003, 5004, 10004),
    ('Kontrabassonsoitto, taso A', 1, 3, '01:00:00', 2, 10, 3012, 5004, 10004),
    ('Kanteleensoitto (musiikin kandidaatti)', 1, 4, '01:00:00', 1, 10, 3004, 5004, 10004),
    ('Yhteissoitto / kantele', 6, 1, '01:30:00', 1, 20, 3004, 5004, 10004),
    ('Urkujensoitto (musiikin kandidaatti)', 1, 3, '01:30:00', 1, 20, 3028, 5004, 10004),
    ('Yhteissoitto / kitara', 5, 1, '01:30:00', 1, 25, 3003, 5004, 10004),
    ('Huilunsoitto, taso A', 1, 5, '01:00:00', 1, 10, 3025, 5004, 10004),
    ('Fortepianonsoitto 1', 1, 7, '01:10:00', 2, 20, 3008, 5004, 10004),
    ('Nokkahuilunsoitto, taso B', 1, 3, '01:00:00', 1, 10, 3025, 5004, 10004),
    ('Viulunsoitto, taso D', 1, 12, '01:00:00', 1, 10, 3012, 5004, 10004),
    ('Tuubansoitto, taso C', 1, 5, '01:00:00', 1, 15, 3025, 5004, 10004),
    ('Harmonikansoitto (musiikin kandidaatti)', 1, 2, '01:00:00', 1, 15, 3010, 5004, 10004),
    ('Jazz, rumpujensoitto, taso B', 1, 4, '01:00:00', 1, 15, 3016, 5004, 10004),
    ('Kansanmusiikkiteoria 1', 20, 1, '01:00:00', 2, 30, 3013, 5002, 10004),
    ('Kirkkomusiikin käytännöt 1', 20, 1, '03:00:00', 1, 30, 3014, 5002, 10004),
    ('Nuottikirjoitus', 15, 1, '02:00:00', 1, 25, 3030, 5002, 10004),
    ('Harpun orkesterikirjallisuus', 15, 1, '03:00:00', 1, 25, 3011, 5002, 10004),
    ('Global Orchestra', 12, 2, '02:30:00', 2, 35, 3009, 5004, 10004),
    ('Populaarimusiikin historia', 20, 1, '03:00:00', 1, 30, 3019, 5002, 10004),
    ('Oppimaan oppiminen', 15, 2, '02:30:00', 1, 25, 3030, 5002, 10004),
    ('Body Mapping', 25, 2, '02:30:00', 2, 35, 3030, 5002, 10004),
    ('Muusikon Terveys', 20, 1, '02:30:00', 1, 30, 3030, 5002, 10004),
    ('Pianomusiikin historia', 18, 1, '01:00:00', 1, 30, 3001, 5002, 10004),
    ('Syventävä ensemblelaulu', 4, 3, '00:45:00', 1, 10, 3002, 5004, 10004),
    ('Laulu, pääinstrumentti', 1, 10, '01:00:00', 1, 5, 3002, 5004, 10004),
    ('The jazz line - melodisen jazzimprovisoinnin syventävät opinnot', 14, 1, '02:00:00', 1, 20, 3005, 5002, 10004),
    ('Jazzensemble', 5, 1, '02:00:00', 1, 20, 3007, 5004, 10004),
    ('Äänenkäyttö ja huolto / korrepetitiokoulutus', 4, 3, '01:00:00', 1, 10, 3015, 5004, 10004),
    ('Prima vista / korrepetitiokoulutus', 2, 6, '01:00:00', 1, 15, 3015, 5004, 10004),
    ('Musiikinhistorian lukupiiri', 10, 1, '01:00:00', 1 , 15, 3019, 5002, 10004),
    ('Tohtoriseminaari (sävellys)', 17, 1, '02:00:00', 1, 30, 3019, 5002, 10003),
    ('Musiikkiteknologian perusteet', 15, 1, '01:00:00', 1, 30, 3020, 5004, 10002),
    ('Johtamisen pedagogiikka -luentosarja', 10, 1, '02:00:00', 1, 20, 3018, 5002, 10001);


/* --- Insert: SubjectEquipment * --- */
INSERT INTO SubjectEquipment(subjectId, equipmentId, priority) VALUES
    (4003, 2021, 900),
    (4004, 2017, 50),
    (4005, 2001, 900),
    (4007, 2011, 100),
    (4008, 2009, 90),
    (4009, 2002, 50),
    (4010, 2002, 90),
    (4011, 2001, 900),
    (4012, 2011, 90),
    (4013, 2012, 50),
    (4014, 2013, 900),
    (4015, 2003, 50),
    (4016, 2006, 90),
    (4017, 2016, 90),
    (4018, 2012, 90),
    (4020, 2010, 400),
    (4003, 2010, 700),
    (4005, 2010, 500),
    (4014, 2010, 500),
    (4031, 2010, 500),
    (4024, 2010, 500),
    (4002, 2011, 400),
    (4024, 2011, 500),
    (4033, 2011, 500),
    (4019, 2004, 700),
    (4005, 2004, 600),
    (4024, 2004, 600),
    (4033, 2004, 600);

/* --- Insert: AllocSubject * --- */
INSERT INTO AllocSubject(subjectId, allocRoundId, isAllocated, allocatedDate, priority) VALUES
    (4011, 10001, 0, '2022-10-28', 1),
    (4014, 10001, 0, '2022-10-28', 2),
    (4019, 10001, 0, '2022-10-28', 3),
    (4013, 10001, 0, '2022-10-28', 4),
    (4001, 10001, 0, '2022-10-28', 5),

    (4011, 10002, 1, '2022-10-28', 1), -- Urkujensoitto, 1ppl, 1:30/4:30, 20m2, musiikkiluokka
    (4003, 10002, 1, '2022-10-28', 2), -- Piano yksilöopetus, 1ppl, 2:30/05:00, 10m2, musiikkiluokka
    (4005, 10002, 1, '2022-10-28', 3), -- Kirkkomusiikin ryhmäsoitto, 5ppl, 2:30/10:00, musiikkiluokka
    (4024, 10002, 1, '2022-10-28', 4), -- Global Orchestra, 12ppl, 2:30/10:00, 35m2, musiikkiluokka
    (4004, 10002, 1, '2022-10-28', 5), -- Trumpetin ryhmäsoitto, 10ppl, 1:30/4:30, 40m2
    (4014, 10002, 1, '2022-10-28', 6), -- fortepianosoitto, 1ppl, 16:20, 30m2, musiikkiluokka,
    (4019, 10002, 1, '2022-10-28', 7), -- jazz rummut, 1ppl, 4:00, 15m2, musiikkiluokka
    (4013, 10002, 1, '2022-10-28', 8), -- huilujensoitto taso a, 1ppl, 05:00, 10m2, musiikkiluokka
    (4002, 10002, 1, '2022-10-28', 9), -- jazz improvisoinnin perusteet, 17ppl, 2:30/5:00, 35m2, musiikkiluokka
    (4016, 10002, 1, '2022-10-28', 10), -- Viulunsoitto taso D, 1ppl, 01:00/12:00, 10m2, musiikkiluokka
    (4017, 10002, 1, '2022-10-28', 11), -- Tuubansoitto Taso C, 1ppl, 01:00/05:00, 15m2, musiikkiluokka
    (4008, 10002, 1, '2022-10-28', 12), -- Kontrabassonsoitto Taso A, 1ppl, 01:00/06:00, 10m2, musiikkiluokka
    (4007, 10002, 1, '2022-10-28', 13), -- Kitaran soiton perusteet, 11ppl, 1:30/03:00, 60m2, musiikkiluokka
    (4023, 10002, 1, '2022-10-28', 14), -- Harpun orkesterikirjallisuus, 15ppl, 3:00, 25m2, teorialuokka
    (4020, 10002, 1, '2022-10-28', 15), -- Kansanmusiikkiteoria 1, 20ppl, 1:00/2:00, 30m2, teorialuokka
    (4027, 10002, 1, '2022-10-28', 16), -- Body mapping, 20, 2:30, 30m2, teorialuokka
    (4028, 10002, 1, '2022-10-28', 17), -- Muusikon terveys, 20ppl, 2:30, 30m2, teorialuokka
    (4021, 10002, 1, '2022-10-28', 18), -- Kirkkomusiikin käytännöt, 20ppl, 03:00, 30m2, teorialuokka
    (4022, 10002, 1, '2022-10-28', 19), -- Nuottikirjoitus, 15ppl, 2:00, 25m2, teorialuokka
    (4001, 10002, 1, '2022-10-28', 20), -- saksan kielen perusteet, 10ppl, 06:00, 35m2, teorialuokka
    (4006, 10002, 1, '2022-10-28', 21), -- Ruotsin kielen oppintunti, 40ppl, 1:45/3:30, 40m2, teorialuokka
    (4018, 10002, 1, '2022-10-28', 22), -- Harmonikansoitto, 1ppl, 01:00/02:00, 15m2, musiikkiluokka
    (4029, 10002, 1, '2022-10-28', 23), -- pianomusiikin historia, 24ppl, 01:00, 30m2, teorialuokka
    (4030, 10002, 1, '2022-10-28', 24), -- Syventävä ensemblelaulu, 4ppl, 00:45/01:45, 10m2, musiikkiluokka
    (4031, 10002, 1, '2022-10-28', 25), -- Laulu, pääinstrumentti, 1ppl, 01:00/10:00, 5m2, musiikkiluokka
    (4009, 10002, 1, '2022-10-28', 26), -- kanteleensoitto, 1ppl, 01:00/04:00, 10m2, musiikkiluokka
    (4032, 10002, 1, '2022-10-28', 27), -- the jazz line, 14ppl, 02:00, 20m2, musiikkiluokka
    (4033, 10002, 1, '2022-10-28', 28), -- Jazzensemble, 5ppl, 02:00, 20m2, musiikkiluokka
    (4034, 10002, 1, '2022-10-28', 29), -- Äänenkäyttö ja huolto / korrepetitiokoulutus,
    (4035, 10002, 1, '2022-10-28', 30), -- Prima vista / korrepetitiokoulutus
    (4036, 10002, 1, '2022-10-28', 31), -- Musiikinhistorian lukupiiri
    (4037, 10002, 1, '2022-10-28', 32), -- Tohtoriseminaari (sävellys)
    (4038, 10002, 1, '2022-10-28', 33), -- Musiikkiteknologian perusteet
    (4039, 10002, 1, '2022-10-28', 34), -- Johtamisen pedagogiikka -luentosarja

    (4001, 10003, 0, '2022-09-21', 1),
    (4002, 10003, 0, '2022-09-21', 2),
    (4003, 10003, 0, '2022-09-21', 3),
    (4004, 10003, 0, '2022-09-21', 4),
    (4005, 10003, 0, '2022-09-21', 5),
    (4006, 10003, 0, '2022-09-21', 6),
    (4007, 10003, 0, '2022-09-21', 7);

INSERT INTO AllocSpace(subjectId, allocRoundId, spaceId, totalTime) VALUES
    (4011, 10002, 1020, '04:30:00'), -- Urkujensoitto 1ppl/ N419 urkuluokka, 34m2, 5ppl
    (4003, 10002, 1009, '05:00:00'), -- Pianon yksilöopetus 1ppl/ musiikkiluokka 16.6m2, 6ppl
    (4005, 10002, 1020, '10:00:00'), -- Kirkkomusiikin ryhmäsoitto 5ppl/ N419 Kirkkomusiikki, 34m2, 5ppl
    (4024, 10002, 1016, '10:00:00'), -- Global Orchestra 12ppl/ musiikkiluokka 53m2, 17ppl
    (4004, 10002, 1016, '04:30:00'), -- Trumpetin ryhmäsoitto 10ppl/ R531 Musiikkiluokka, 33m2, 8ppl
    (4014, 10002, 1009, '16:20:00'), -- Fortepianonsoitto 1ppl/ R312 Musiikkiluokka, 16.6m2, 6ppl
    (4019, 10002, 1018, '04:00:00'), -- Jazz rummut 1ppl/ S6114 Perkussioluokka, 33.3m2, 4ppl
    (4013, 10002, 1009, '05:00:00'), -- Huilujensoitto taso A 1ppl/ R312 Musiikkiluokka, 16.6m2, 6ppl
    (4002, 10002, 1016, '05:00:00'), -- Jazz improvisoinnin perusteet 17ppl/ R531 Musiikkiluokka, 53m2, 17ppl
    (4016, 10002, 1009, '12:00:00'), -- Viulunsoitto taso D 1ppl/ R312 Musiikkiluokka, 16.6m2, 6ppl
    (4017, 10002, 1009, '05:00:00'), -- Tuubansoitto taso C 1ppl/ R312 Musiikkiluokka, 16.6m2, 6ppl
    (4008, 10002, 1009, '06:00:00'), -- Kontrabassonsoitto taso A 1ppl/ R313 Musiikkiluokka, 16.6m2, 6ppl
    (4007, 10002, 1016, '03:00:00'), -- Kitaran soiton perusteet 11ppl/ R422 Opetusluokka (Kitara), 23m2, 11ppl
    (4023, 10002, 1010, '03:00:00'), -- Harpun orkesterikirjallisuus 15ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4020, 10002, 1010, '02:00:00'), -- Kansanmusiikinteoria 1 20ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4027, 10002, 1010, '02:30:00'), -- Body Mapping 20ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4028, 10002, 1010, '02:30:00'), -- Musiikin terveys 20ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4021, 10002, 1010, '03:00:00'), -- Kirkkomusiikin käytännöt 20ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4022, 10002, 1010, '02:00:00'), -- Nuottikirjoitus 15ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4001, 10002, 1010, '06:00:00'), -- Saksan kielen perusteet 10ppl/ R530 Luentoluokka, 50m2, 18ppl
    (4006, 10002, 1010, '03:30:00'), -- Ruotsin kielen oppitunti 40ppl/ R530 Luentoluokka, 50m2, 18ppl

    (4018, 10002, 1009, '02:00:00'), -- harmonikansoitto / R312 Musiikkiluokka, 16.6m2, 6ppl
    (4029, 10002, 1010, '01:00:00'), -- pianonmusiikin historia / R512 Luentoluokka, 81m2, 30ppl
    (4030, 10002, 1016, '02:25:00'), -- syventävä ensemblelaulu / N522 säestysluokka, 33m2, 8ppl
    (4031, 10002, 1016, '10:00:00'), -- laulu pääinstrumentti / N517 Musiikkiluokka, 15.5m2, 3ppl
    (4009, 10002, 1016, '04:00:00'), -- kanteleensoitto / N517 Musiikkiluokka, 15.5m2, 3ppl
    (4032, 10002, 1010, '02:00:00'), -- jazz line / Studio Erkki, 36m2, 15ppl
    (4033, 10002, 1018, '02:00:00'), -- jazz endemble / N319 Jazz/Lyömä/piano/yhtyeet, 34m2, 5ppl
    (4034, 10002, 1016, '03:00:00'), -- Äänenkäyttö ja huolto / korrepetitiokoulutus 4ppl, N522 Säestysluokka, 33m2, 8m2
    (4035, 10002, 1018, '06:00:00'), -- Prima vista / korrepetitiokoulutus 2ppl, N319 piano, 34m2, 5ppl
    (4036, 10002, 1010, '01:00:00'), -- Musiikinhistorian lukupiiri 10ppl / R530 Opetusluokka, 50m2, 18ppl
    (4037, 10002, 1010, '02:00:00'), -- Tohtoriseminaari (sävellys) 17ppl / R530 Opetusluokka, 59m2, 18ppl
    (4038, 10002, 1010, '01:00:00'), -- Musiikkiteknologian perusteet 10ppl
    (4039, 10002, 1010, '02:00:00'); -- Johtamisen pedagogiikka -luentosarja 15ppl

/* --- Insert: AllocCurrentRoundUser * --- */
INSERT INTO AllocCurrentRoundUser(allocRoundId, userId) VALUES
    (10001, 201),
    (10001, 202),
    (10002, 201);

/* --- INSERT: LOG TYPE --- */
INSERT INTO log_type(name) VALUES ("allocation");

/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */
/* -------------------------- END --------------------------- */
/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */

