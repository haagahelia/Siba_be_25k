USE casedb; /* UPDATED 2023-11-05 */

/* PROCEDURES */
/* DELIMITER is explained here, just look at first two examples: https://mariadb.com/kb/en/delimiters/ */

-- -----------------------------------------------------------
-- Copy Alloc Round. Copies the allocRound subjects, but not yet the SubjectEquipment
DELIMITER //
CREATE OR REPLACE PROCEDURE copyAllocRound(IN allocRid1 INT, 
                                        IN allocRoundName2 VARCHAR(255), 
                                        IN allocRoundDescription2 VARCHAR(16000),
                                        IN creatorUserId2 INT,
                                        OUT allocRid2 INT)
BEGIN
    INSERT INTO AllocRound
        (`date`, name, isSeasonAlloc, userId, 
        description, lastModified, isAllocated, 
            processOn, abortProcess, requireReset)
    VALUES(
        NULL, allocRoundName2, 0, creatorUserId2, 
        allocRoundDescription2, current_timestamp(), 0,
            0, 0, 0);

    SET allocRid2 = last_insert_id();

    INSERT INTO Subject 
                    (name,     groupSize,     groupCount,    sessionLength, 
                       sessionCount,    area,    programId,    spaceTypeId, allocRoundId)
    
            SELECT s1.name, s1.groupSize, s1.groupCount, s1.sessionLength, 
                    s1.sessionCount, s1.area, s1.programId, s1.spaceTypeId, allocRid2
            FROM Subject s1
                WHERE (s1.allocRoundId = allocRid1);
            
    INSERT INTO SubjectEquipment  
                    (subjectId, equipmentId, priority, obligatory)
            SELECT s2.id, se1.equipmentId, se1.priority, se1.obligatory
            
            FROM Subject s2 JOIN Subject s1 ON s2.name = s1.name 
                 JOIN SubjectEquipment se1 ON s1.id = se1.subjectId 
                 WHERE s2.allocRoundId = allocRid2 AND s1.allocRoundId = allocRid1;
    
    SHOW ERRORS;
    
END;
//
DELIMITER ;
-- ------------------------------------------------------------------------------------------------------
DELIMITER //
CREATE OR REPLACE PROCEDURE test_copyAllocRound()
BEGIN
    DECLARE allocRid               INTEGER        DEFAULT  10004;
    DECLARE random                 DOUBLE         DEFAULT RAND(); 
    DECLARE allocRoundName         VARCHAR(255)   DEFAULT   CONCAT('Copied test alloc round',random);
    DECLARE allocRoundDescription  VARCHAR(16000) DEFAULT   'Alloc round based on 10004';
    DECLARE creatorUserId          INTEGER        DEFAULT   201;
    DECLARE allocRid2              INTEGER        DEFAULT -1;

    CALL copyAllocRound(allocRid, 
                        allocRoundName, 
                        allocRoundDescription,
                        creatorUserId,
                        allocRid2);
    SELECT allocRid2;
                
END;
//
DELIMITER ;

-- -----------------------------------------------------------

/* --- Procedure 1: Conditional database logger, used by other prodedures below --- */
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS LogAllocation(logId INT, stage VARCHAR(255), status VARCHAR(255), msg VARCHAR(16000))
BEGIN
	DECLARE debug INTEGER;

	SET debug := (SELECT numberValue FROM GlobalSetting WHERE variable='allocation-debug');

	IF debug = 1 AND logId IS NOT NULL AND logId != 0 THEN
		INSERT INTO log_event(log_id, stage, status, information) VALUES(logId, stage, status, msg);
	END IF;
END;
//
DELIMITER ;

/* allocRid is now used for the frontend sent allocRoundId, to make it stand out e.g. in:
  AllocSpace.allocRoundId = allocRid;
  Easier to follow, Right? */


/* --- Procedure 2: PRIORITIZE SUBJECTS -  TO ALLOCATION ORDER --- */
DELIMITER //

CREATE OR REPLACE PROCEDURE prioritizeSubjects(allocRid INT, priority_option INT, logId INT)
BEGIN
	DECLARE priorityNow INTEGER;

	SET priorityNow = (SELECT IFNULL(MAX(priority),0) FROM AllocSubject allSub WHERE allSub.allocRoundId = allocRid);

	IF priority_option = 1 THEN -- subject_equipment.priority >= highPriority
		INSERT INTO AllocSubject (subjectId, allocRoundId, priority)
			SELECT allSub.subjectId, allSub.allocRoundId, ROW_NUMBER() OVER (ORDER BY MAX(sub_eqp.priority) DESC, Subject.groupSize ASC) + priorityNow as "row"
    		FROM AllocSubject allSub
    		LEFT JOIN SubjectEquipment sub_eqp ON allSub.subjectId = sub_eqp.subjectId
    		JOIN Subject ON allSub.subjectId = Subject.id
    		WHERE allSub.allocRoundId = allocRid AND allSub.priority IS NULL
    		AND (sub_eqp.priority) >= (SELECT numberValue FROM GlobalSetting gs WHERE variable="highPriority")
    		GROUP BY allSub.subjectId
		ON DUPLICATE KEY UPDATE priority = VALUES(priority);
	ELSEIF priority_option = 2 THEN -- subject_equipment.priority < highPriority
		INSERT INTO AllocSubject (subjectId, allocRoundId, priority)
			SELECT allSub.subjectId, allSub.allocRoundId, ROW_NUMBER() OVER (ORDER BY MAX(sub_eqp.priority) DESC, Subject.groupSize ASC) + priorityNow as "row"
       		FROM AllocSubject allSub
        	LEFT JOIN SubjectEquipment sub_eqp ON allSub.subjectId = sub_eqp.subjectId
        	JOIN Subject ON allSub.subjectId = Subject.id
        	WHERE allSub.allocRoundId = allocRid
        	AND allSub.priority IS NULL
        	AND (sub_eqp.priority) < (SELECT numberValue FROM GlobalSetting gs WHERE variable="highPriority")
        	GROUP BY allSub.subjectId
        	ORDER BY sub_eqp.priority DESC
        ON DUPLICATE KEY UPDATE priority = VALUES(priority);
    ELSEIF priority_option = 3 THEN -- all others (subjects without equipment)
    	INSERT INTO AllocSubject (subjectId, allocRoundId, priority)
    		SELECT AllocSubject.subjectId, AllocSubject.allocRoundId, ROW_NUMBER() OVER (ORDER BY Subject.groupSize ASC) + priorityNow as "row"
			FROM AllocSubject
			LEFT JOIN Subject ON AllocSubject.subjectId = Subject.id
			WHERE priority IS NULL
			AND AllocSubject.allocRoundId = allocRid
		ON DUPLICATE KEY UPDATE priority = VALUES(priority);
	END IF;

	CALL LogAllocation(logId, "Prioritization", "OK", CONCAT("Priority option: ", priority_option, " completed."));

END;
//
DELIMITER ;

/* --- Procedure 3: SET SUITABLE ROOMS -  Find which spaces could be suitable for this subject id - ALLOCATION --- */
DELIMITER //

CREATE OR REPLACE PROCEDURE setSuitableRooms(allocRid INT, subId INT)
BEGIN
	INSERT INTO AllocSubjectSuitableSpace (allocRoundId, subjectId, spaceId, missingItems)
		SELECT allocRid, subId, sp.id, getMissingItemAmount(subId, sp.id) AS "missingItems"
		FROM Space sp
		WHERE sp.personLimit >= (SELECT groupSize FROM Subject WHERE id=subId)
		AND sp.area >= (SELECT s.area FROM Subject s WHERE id=subId)
		AND sp.spaceTypeId = (SELECT s.spaceTypeId FROM Subject s WHERE id=subId)
		AND sp.inUse=1
		;
END;
//
DELIMITER ;

/* --- Procedure 4: allocated space(s) to satisfy the subject's needs - until all needed hours have been allocated --- */
DELIMITER //

CREATE PROCEDURE allocateSpace(allocRid INT, subId INT, logId INT)
BEGIN
	DECLARE spaceTo INTEGER DEFAULT NULL;
	DECLARE i INTEGER DEFAULT 0; -- loop index
	DECLARE sessions INTEGER DEFAULT 0; -- Total session amount = groupCount * sessionCount
	DECLARE allocated INTEGER DEFAULT 0; -- How many sessions added to AllocSpace
	DECLARE sessionSeconds INTEGER DEFAULT 0; -- How many seconds each session lasts
	DECLARE suitableSpaces BOOLEAN DEFAULT TRUE; -- If can't allocate set false
	DECLARE loopOn BOOLEAN DEFAULT TRUE; -- while loop condition

	SET sessions := (SELECT groupCount * sessionCount FROM Subject WHERE id = subId); -- total amount of sessions in subject
   	SET allocated := 0; -- How many sessions allocated
   	SET sessionSeconds := (SELECT CEILING(TIME_TO_SEC(sessionLength)) FROM Subject WHERE id = subId); -- Session length in seconds

	SET spaceTo := ( -- to check if subject can be allocated
        	SELECT ass.spaceId FROM AllocSubjectSuitableSpace ass
        	WHERE ass.missingItems = 0 AND ass.subjectId = subId AND ass.allocRoundId = allocRid
 			LIMIT 1);

	IF spaceTo IS NULL THEN -- If can't find suitable spaces
		SET suitableSpaces := FALSE;
   	ELSE -- Find for each session space with free time
   		SET i := 0;
   		WHILE loopOn DO -- Try add all sessions to the space
   			SET spaceTo := (SELECT sp.id FROM AllocSubjectSuitableSpace ass
							LEFT JOIN Space sp ON ass.spaceId = sp.id
							WHERE ass.subjectId = subId AND ass.missingItems = 0 AND ass.allocRoundId = allocRid
							GROUP BY sp.id
							HAVING
							((SELECT TIME_TO_SEC(TIMEDIFF(availableTo, availableFrom)) *5 FROM Space WHERE id = sp.id) -
								(SELECT IFNULL(SUM(TIME_TO_SEC(totalTime)), 0) FROM AllocSpace asp WHERE asp.allocRoundId = allocRid AND spaceId = sp.id)
								>
								(sessionSeconds * (sessions - i - allocated)))
							ORDER BY sp.personLimit ASC, sp.area ASC
							LIMIT 1);

			IF spaceTo IS NULL THEN -- If can't find space with freetime for specific amount sessions
				SET i := i+1;
				IF i = sessions - allocated THEN -- If checked all
					SET loopOn = FALSE;
				END IF;
			ELSE -- if can find space with freetime for specific amount sessions
			INSERT INTO AllocSpace
					(subjectId, allocRoundId, spaceId, totalTime)
				VALUES
					(subId, allocRid, spaceTo, SEC_TO_TIME((sessionSeconds * (sessions - i - allocated))))
				ON DUPLICATE KEY UPDATE totalTime = ADDTIME(totalTime, (SEC_TO_TIME(sessionSeconds * (sessions - i - allocated))));
				-- LOG HERE
				CALL LogAllocation(logId, "Space-allocation", "OK", CONCAT("Subject : ", subId, " - Allocate ", sessions - i - allocated, " of ", sessions, " sessions to space: ", spaceTo));
				SET allocated := allocated + (sessions - i - allocated);
				SET i := 0;
				IF allocated = sessions THEN
					SET loopOn = FALSE;
				END IF;
			END IF;
   		END WHILE;
   END IF;

   IF sessions = allocated THEN -- If all sessions allocated
   	UPDATE AllocSubject asu SET isAllocated = 1 WHERE asu.subjectId = subId AND asu.allocRoundId = allocRid;
   ELSEIF suitableSpaces = FALSE THEN -- if can't find any suitable space for the subject
   	UPDATE AllocSubject asu SET cantAllocate = 1 WHERE asu.subjectId = subId AND asu.allocRoundId = allocRid;
   	-- LOG HERE
    CALL LogAllocation(logId, "Space-allocation", "Warning", CONCAT("Subject : ", subId, " - Can't find suitable spaces" ));
   ELSEIF allocated = 0 AND suitableSpaces = TRUE THEN -- if can't find any space with free time, add all sessions to same space with most freetime
   		SET spaceTo := (
   			SELECT alpa.spaceId
			FROM AllocSubjectSuitableSpace alpa
			LEFT JOIN Space spa ON alpa.spaceId = spa.id
			WHERE alpa.subjectId = subId
			AND alpa.missingItems = 0
			AND alpa.allocRoundId = allocRid
			GROUP BY alpa.spaceId
			ORDER BY (CEILING((TIME_TO_SEC(TIMEDIFF(spa.availableTO, spa.availableFrom))) *5) -
			(SELECT IFNULL((SUM(CEILING(TIME_TO_SEC(totalTime)))), 0) FROM AllocSpace asp WHERE asp.allocRoundId = allocRid AND spaceId = alpa.spaceId)) DESC
			LIMIT 1
		);
   		INSERT INTO AllocSpace (subjectId, allocRoundId, spaceId, totalTime)
   			VALUES (subId, allocRid, spaceTo, SEC_TO_TIME(sessionSeconds * sessions));
   		UPDATE AllocSubject asu SET isAllocated = 1 WHERE asu.subjectId = subId AND asu.allocRoundId = allocRid;
   		-- LOG HERE
		CALL LogAllocation(logId, "Space-allocation", "Warning", CONCAT("Subject : ", subId, " - Allocate ", sessions, " of ", sessions, " sessions to space: ", spaceTo, " - All suitable spaces are full."));

   	ELSEIF allocated < sessions AND suitableSpaces = TRUE THEN -- if there is free time for some of the sessions but not all, add rest to same space than others
   		SET spaceTo := (SELECT spaceId FROM AllocSpace asp WHERE asp.subjectId = subId AND asp.allocRoundId = allocRid ORDER BY totalTime ASC LIMIT 1);

		UPDATE AllocSpace asp SET totalTime=ADDTIME(totalTime,(SEC_TO_TIME(sessionSeconds * (sessions - allocated))))
		WHERE asp.subjectId=subID AND asp.spaceId = spaceTO AND asp.allocRoundId = allocRid;
		UPDATE AllocSubject asu SET isAllocated = 1 WHERE asu.subjectId = subId AND asu.allocRoundId = allocRid;
		-- LOG HERE
		CALL LogAllocation(logId, "Space-allocation", "Warning", CONCAT("Subject : ", subId, " - Add ", sessions - allocated, " to space: ", spaceTo, " - All suitable spaces are full"));
   	END IF;
END;
//
DELIMITER ;


/* --- Procedure 5 - A: START ALLOCATION --- */
DELIMITER //

CREATE OR REPLACE PROCEDURE startAllocation(allocRid INT)
BEGIN
	DECLARE finished INTEGER DEFAULT 0; -- Marker for loop
	DECLARE subId	INTEGER DEFAULT 0; -- SubjectId
	DECLARE logId	INTEGER DEFAULT NULL;
	DECLARE errors	INTEGER DEFAULT 0;
	DECLARE debug	INTEGER DEFAULT 0;
	DECLARE abort_round	BOOLEAN DEFAULT FALSE;
	DECLARE reset_required	BOOLEAN DEFAULT FALSE;
	DECLARE procedure_active	BOOLEAN DEFAULT FALSE;
	DECLARE is_allocated 	BOOLEAN DEFAULT FALSE;

	-- Error Handling declarations
    DECLARE processBusy CONDITION FOR SQLSTATE '50000';
    DECLARE alreadyAllocated CONDITION FOR SQLSTATE '50001';
	DECLARE abortAllocation	CONDITION FOR SQLSTATE '50002';
	DECLARE require_reset	CONDITION FOR SQLSTATE '50003';

	-- Cursor for subject loop / SELECT priority order
	DECLARE subjects CURSOR FOR
		SELECT allSub.subjectId
       	FROM AllocSubject allSub
        WHERE allSub.allocRoundId = allocRid
        ORDER BY priority ASC;

	DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

	-- IF user tell to abort the process
	DECLARE EXIT HANDLER FOR abortAllocation
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("Error: ", @errno, " (", @sqlstate, "): ", @text);
		CALL LogAllocation(logId, "Allocation", "Error", (SELECT @full_error));
		UPDATE AllocRound SET abortProcess = 0, processOn = 0, lastCalcFail = current_timestamp() WHERE id = allocRid;
		RESIGNAL SET MESSAGE_TEXT = @full_error;
	END;

	-- IF Procedure already running, is already allocated
	DECLARE EXIT HANDLER FOR processBusy, alreadyAllocated, require_reset
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("Error: ", @errno, " (", @sqlstate, "): ", @text);
		CALL LogAllocation(logId, "Allocation", "Error", (SELECT @full_error));
		UPDATE AllocRound SET lastCalcFail = current_timestamp() WHERE id = allocRid;
		RESIGNAL SET MESSAGE_TEXT = @full_error;
	END;

	-- IF ANY ERROR HAPPEN INSERT IT TO DEBUG LOG
	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
		BEGIN
			SET errors := errors +1;
			GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
			SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
			UPDATE AllocRound SET lastCalcFail = current_timestamp() WHERE id = allocRid;
			CALL LogAllocation(logId, "Allocation", "Error", (SELECT @full_error));
		END;

	-- IF debug mode on, start logging.
	SET debug := (SELECT numberValue FROM GlobalSetting WHERE variable='allocation-debug');
	IF debug = 1 THEN
		INSERT INTO log_list(log_type) VALUES (1); -- START LOG
		SET logId := (SELECT LAST_INSERT_ID()); -- SET log id number for the list
	END IF;

	CALL LogAllocation(logId, "Allocation", "Start", CONCAT("Start allocation. AllocRound: ", allocRid));

	-- IF allocRound already allocated raise error
	SET is_allocated = (SELECT isAllocated FROM AllocRound WHERE id = allocRid);
	IF is_allocated = 1 THEN
		SET @message_text = CONCAT("The allocRound: ", allocRid, " is already allocated.");
		SIGNAL alreadyAllocated SET MESSAGE_TEXT = @message_text, MYSQL_ERRNO = 1192;
		UPDATE AllocRound SET lastCalcFail = current_timestamp() WHERE id = allocRid;
	END IF;
	-- IF AllocRound require reset before allocation
	SET reset_required = (SELECT requireReset FROM AllocRound WHERE id = allocRid);
	IF reset_required = TRUE THEN
		SET @message_text = CONCAT("The allocRound: ", allocRid, " require reset before allocation.");
		SIGNAL require_reset SET MESSAGE_TEXT = @message_text, MYSQL_ERRNO = 1192;
		UPDATE AllocRound SET lastCalcFail = current_timestamp() WHERE id = allocRid;
	END IF;
	-- IF Allocation already running with allocRound id raise error
	SET procedure_active = (SELECT processOn FROM AllocRound WHERE id = allocRid);
	IF procedure_active = 1 THEN
		SET @message_text = CONCAT("The allocation with allocRound:", allocRid, " is already running.");
		SIGNAL processBusy SET MESSAGE_TEXT = @message_text, MYSQL_ERRNO = 1192;
		UPDATE AllocRound SET lastCalcFail = current_timestamp() WHERE id = allocRid;
	END IF;
	-- SET procedure running
	UPDATE AllocRound SET processOn = 1 WHERE id = allocRid;

	/* ONLY FOR DEMO PURPOSES */
	IF (allocRid = 10004) THEN
		INSERT INTO AllocSubject(subjectId, allocRoundId)
		SELECT id, 10004 FROM Subject;
	END IF;
	/* DEMO PART ENDS */

	UPDATE AllocRound SET requireReset = TRUE WHERE id = allocRid;

	CALL prioritizeSubjects(allocRid, 1, logId); -- sub_eq.prior >= highPriority ORDER BY sub_eq.prior DESC, groupSize ASC
	CALL prioritizeSubjects(allocRid, 2, logId); -- sub_eq.prior < highPriority ORDER BY sub_eq.prior DESC, groupSize ASC
	CALL prioritizeSubjects(allocRid, 3, logId); -- without equipments ORDER BY groupSize ASC

	OPEN subjects;

	subjectLoop : LOOP
		FETCH subjects INTO subId;
		IF finished = 1 THEN LEAVE subjectLoop;
		END IF;

		-- IF user tells abort the process.
		SET abort_round := (SELECT abortProcess FROM AllocRound WHERE id = allocRid);
		IF abort_round = 1 THEN
			SET @message_text = CONCAT("The allocation been terminated by user. AllocRoundId: ", allocRid, ".");
			SIGNAL abortAllocation SET MESSAGE_TEXT = @message_text, MYSQL_ERRNO = 1192;
		END IF;

		-- SET Suitable rooms for the subject
		CALL LogAllocation(logId, "Allocation", "Info", CONCAT("SubjectId: ", subId, " - Search for suitable spaces"));
	    CALL setSuitableRooms(allocRid, subId);
		-- SET cantAllocate or Insert subject to spaces
        CALL allocateSpace(allocRid, subId, logId);

	END LOOP subjectLoop;

	CLOSE subjects;

	UPDATE AllocRound SET isAllocated = 1 WHERE id = allocRid;
	CALL LogAllocation(logId, "Allocation", "End", CONCAT("Errors: ", (SELECT errors)));

	UPDATE AllocRound SET processOn = 0, lastCalcSuccs = current_timestamp() WHERE id = allocRid;

END;
//
DELIMITER ;
                       /* ---   TIMESPAN 75:59:59:999   vs.  TIME?  23:59:59:999 --- */

/* --- PROCEDURE 6 - B: Abort Allocation --- */
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS abortAllocation(allocRid INT)	
BEGIN
	DECLARE inProgress BOOLEAN DEFAULT FALSE;

	-- CHECK IF Allocation is active
	SET inProgress := (SELECT processOn FROM AllocRound WHERE id = allocRid);
	-- IF in process tell to stop
	IF inProgress = TRUE THEN
		UPDATE AllocRound SET abortProcess = 1 WHERE id = allocRid;
	END IF;

END;
//
DELIMITER ;


/* --- Procedure 7 - C: RESET ALLOCATION, will nullify all calculations/allocations for this alloc R(ound) Id --- */
DELIMITER //

CREATE PROCEDURE IF NOT EXISTS  resetAllocation(allocRid INTEGER)
BEGIN

	-- Handler for the error
	DECLARE processBusy CONDITION FOR SQLSTATE '50000';
	DECLARE EXIT HANDLER FOR processBusy
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("Error: ", @errno, " (", @sqlstate, "): ", @text);
		RESIGNAL SET MESSAGE_TEXT = @full_error;
	END;
	-- Raise error if allocation in progress.
	SET @procedure_active = (SELECT processOn FROM AllocRound WHERE id = allocRid);
	IF @procedure_active = 1 THEN
		SET @message_text = CONCAT("The allocation with allocRound:", allocRid, " is currently in progress.");
		SIGNAL processBusy SET MESSAGE_TEXT = @message_text, MYSQL_ERRNO = 1192;
	END IF;

	-- Delete all allocation data and reset variables
	DELETE FROM AllocSpace WHERE allocRoundId = allocRid;
	DELETE FROM AllocSubjectSuitableSpace WHERE allocRoundId = allocRid;
    IF (allocRid = 10004) THEN
        DELETE FROM AllocSubject WHERE allocRoundId = 10004;
    ELSE
	    UPDATE AllocSubject SET isAllocated = 0, priority = null, cantAllocate = 0 WHERE allocRoundId = allocRid;
    END IF;
    UPDATE AllocRound SET isAllocated = 0, requireReset = FALSE WHERE id = allocRid;
END;
//
DELIMITER ;


/* ------------------------------------------------------ */
/* FUNCTIONS */

/* Function 8 (well 1-7 were actually procedures, but similar) - Get missing equipment(subject) count in space */
DELIMITER //

CREATE FUNCTION IF NOT EXISTS getMissingItemAmount(subId INT, spaId INT) RETURNS INT
NOT DETERMINISTIC
BEGIN
RETURN (
	SELECT COUNT(*)
        FROM(
    		SELECT equipmentId  FROM SubjectEquipment
    				WHERE SubjectEquipment.subjectId = subId
    			EXCEPT
    		SELECT equipmentId FROM SpaceEquipment
    				WHERE SpaceEquipment.spaceId = spaId
		) a
);
END;
//
DELIMITER ;

/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */
/* -------------------------- END --------------------------- */
/* ---------------------------------------------------------- */
/* ---------------------------------------------------------- */

