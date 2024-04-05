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
    acronym     VARCHAR(255)    NOT NULL,
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

