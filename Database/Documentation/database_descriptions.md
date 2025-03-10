# Descriptions of the database tables

<details><summary>AllocCurrentRoundUser</summary>

***Not in use, at least not yet**

|Column			        |	Datatype	|	Keys 	    |	Description
|:-----			        | :------- 		| 	------- 	|	------
|<u>allocRoundId</u>	| INTEGER		| PK 			|
|<u>UserId</u>          | INTEGER		| PK, FK   		| => User.id

</details>

<details><summary>AllocRound</summary>
<small> (Allocation calculations e.g. for a certain semester. E.g. "Summer semester 2023") </small>

Column			|	Datatype	|	Keys		|	Description
:-----			|	:---		|	-------		|	------
 <u>id</u>		| INTEGER		| PK			|
 date			| TIMESTAMP 	|				| Allocation's creation time
 name			| VARCHAR(255)	|				| Allocation's name. eg. "Syksyn 2022 virallinen"
 isSeasonAlloc	| BOOLEAN 		|				| Whether semester active *NOT IN USE*
 userId			| INTEGER		| FK(User.id)	| Allocation's creator/maintainer
 description 	| VARCHAR(16000)|				| Possible description for allocation
 lastModified 	| TIMESTAMP 	|				| Last modification for allocation
 isAllocated    | BOOLEAN       |               | Whether allocation completed
 processOn      | BOOLEAN       |               | Whether allocation on-going at the moment
 abortProcess   | BOOLEAN       |               | TRUE = admin has given the order to interrupt the allocation before completion
 requireReset   | BOOLEAN       |               | Should allocation be reset, before the allocation can be restarted from scratch again

</details>

<details><summary>AllocSpace</summary>
<small> (Space reservations / allocations) </small>

 Column			|	Datatype	|	Keys			            	|	Description
 :-----			|	:----		|	------			            	|	------
 subjectId      | INTEGER		| PK, FK(AllocSubject.subjectId)	|
 allocRoundId     | INTEGER		| PK, FK(AllocSubject.allocRoundId)	|
 spaceId 		| INTEGER		| PK, FK(Space.id)	            	|
 totalTime		| TIME			|					            	| How many hours this subject took on that allocround in this room

</details>

<details><summary>AllocSubject</summary>
<small> (Subjects for allocation) </small>

Column			    |	Datatype	|	Keys		        |	Description
:-----			    |	:----		|	------		        |	------
<u>subjectId</u>    | INTEGER		|PK,FK(Subject.id)      | Subject added to the allocation
<u>allocRoundId</u>   | INTEGER		|PK,FK(AllocRound.id)   |
isAllocated 	    | BOOLEAN		|				        | Whether subject already handled in this allocRound
cantAllocate 	    | BOOLEAN		|				        | Marking True(1) when no suitable spaces found for this subject for this allocRound
priority		    | INTEGER		|				        | Ordinal for subjects - Number one allocated first to spaces, then two and so on
allocatedDate 	    | TIMESTAMP		|				        | Timestamp of the allocation process

</details>

<details><summary>AllocSubjectSuitableSpace</summary>
<small>(All spaces that could be used to allocate a certain subject)</small>

Column			    |	Datatype	|	Keys		                    |	Description
:-----			    |	:----		|	------		                    |	------
<u>allocRoundId</u>   |  INTEGER      | PK, FK(AllocSubject.allocRoundId)   |
<u>subjectId</u>    |  INTEGER      | PK, FK(AllocSubject.subjectId)    |
<u>spaceId</u>      |  INTEGER      | PK, FK(Space.id)                  |
 missingItems       |  INTEGER		|									| Number of missing equipment, number of reasons why allocation could not happen
</details>


<details><summary>Building</summary>
<small>Building where the spaces reside</small>

Column			|	Datatype	|	Keys		|	Description
:-----			|	:----		|	------		|	------
<u>id</u>		| INTEGER		| PK			|
name			| VARCHAR(255)	|				| e.g. "N-talo", "M-talo"
description		| VARCHAR(16000)|				|

</details>


<details><summary>Department</summary>
Bigger educational entity than Program. Department has Programs.

Column			|	Datatype	|	Keys		|	Description
:-----			|	:----		|	------		|	------
<u>id</u>		| INTEGER		| PK			|
name			| VARCHAR(255)	|				| e.g "Jazz department", or "Church music"
description		| VARCHAR(16000)|				|

</details>

<details><summary>DepartmentPlanner</summary>
<small> (A user who has rights to modify that Department's Programs' teachings and equipment needs) </small>

Column				|	Datatype	|	Keys				|	Description
:-----				|	:----		|	------				|	------
<u>departmentId</u> | INTEGER		| PK, FK(deparment.id)	|
<u>userId</u>		| INTEGER		| PK, FK(user.id)		|

</details>

<details><summary>Equipment</summary>
<small> (Actually equipment type, e.g. "Double concert piano" means room could have two pianos, one for professor, one for student) </small>

Column			|	Datatype	|	Keys		|	Description
:-----			|	:----		|	------		|	------
<u>id</u>		| INTEGER		| PK			|
name			| VARCHAR(255)	| 				| e.g. "Organ X", "Double concert piano", "Concert piano", "Vertical accompany piano"
isMovable		| BOOLEAN		| 				| Whether equipment movable. E.g. huge organs are not.
priority		| INTEGER		|				| (Is this in use in calculations yet?)
description		| VARCHAR(16000)|				|

</details>

<details><summary>GlobalSetting</summary>
<small> (Global Settings in the system. Growin and growing. Maybe adding a AllocSettings-taulu for allocation separately? Or in same) </small>

Column			|	Datatype	|	Keys		|	Description
:-----			|	:----		|	------		|	------
<u>id</u>		| INTEGER		| PK			|
name			| VARCHAR(255)	| 				| Name of the setting
description		| VARCHAR(16000)|				| Description for the setting
numberValue		| INTEGER		| 				| If setting needs a number value, it will be saved here, and read from here
textValue		| VARCHAR(255)	|				| If setting needs a text value, it will be saved here, and read from here
booleanValue    | BOOLEAN       |               | If setting needs a boolean value, it will be saved and read from here.
decimalValue    | DECIMAL       |               | If setting needs a decimal value, it will be saved and read from here.

</details>

<details><summary>Program</summary>
<small> (Program ('pääaine'), e.g. "Orchestral music") </small>

Column			|	Datatype	|	Keys			|	Description
:-----			|	:----		|	------			|	------
<u>id</u>		| INTEGER		| PK				|
name			| VARCHAR(255)	|					|
departmentId	| INTEGER		| FK(department.id)	| Under which Department this Program belongs to

</details>

<details><summary>Space</summary>
<small>(A certain Room, space, studio, classroom etc.) </small>

Column			|	Datatype	|	Keys			|	Description
:-----			|	:----		|	------			|	------
<u>id</u>		| INTEGER		|PK					|
name			| VARCHAR(255)	|					| E.g. "R-5322 Musiikkiluokka"
area			| DECIMAL(5,1)	|					| m²
info			| VARCHAR(16000)|					| Description
personLimit 	| INTEGER		|					| Max pax
buildingId		| INTEGER		|FK(building.id)	| In which building is this space?
availableFrom	| TIME			|					| Daily time when any use could start
availableTo		| TIME			|					| Daily time until when any use possible
classesFrom		| TIME			|					| Daily time when teaching sessions could start
classesTo		| TIME			|					| Daily time until when teaching sessions possible
inUse			| BOOLEAN		|					| Whether space in use, or e.g. under renovation
spaceTypeId		| INTEGER		|FK(spaceType.id)	| E.g. theory classroom, music classroom, recording studio, etc.

</details>

<details><summary>SpaceEquipment</summary>
<small> (Equipment found in a Space (instruments, appliances, furniture, ...)) </small>
<small> (A pure join table) </small>

Column				|	Datatype	|	Keys				|	Description
:-----				|	:----		|	------				|	------
<u>spaceId</u>		| INTEGER		|PK, FK(space.id)		|
<u>equipmentId</u>	| INTEGER		|PK, FK(equipment.id)	|

</details>

<details><summary>SpaceType</summary>
<small> (E.g. theory classroom, music classroom, recording studio, etc.)</small>

Column			|	Datatype	|	Keys		|	Description
:-----			|	:----		|	------		|	------
<u>id</u>		| INTEGER		| PK			|
name			| VARCHAR(255)	|				|
description		| VARCHAR(16000)|				| Possible description

</details>

<details><summary>Subject</summary>
<small> (Teaching. One course might have several teachings=Subjects. 1. theory for all together and 2. e.g. individual piano lessons) </small>
<small> (We only keep the teaching sessions. Courses are not kept) </small>

Column			|	Datatype	|	Keys			|	Description
:-----			|	:----		|	------			|	------
<u>id</u>		| INTEGER		| PK				|
name			| VARCHAR(255)	|					| E.g. "Pianist individual piano lessons"
groupSize		| INTEGER		|					|
groupCount		| INTEGER		|					| How many groups.
sessionLength	| TIME			|					| How long teaching sessions
sessionCount	| INTEGER		|					| How many sessions per week
area			| DECIMAL(5,1)	|					| Needed room size (m²)
programId		| INTEGER		|FK(program.id)		| The program under which this teaching/Subject is organized
spaceTypeId		| INTEGER		|FK(spaceType.id)	| What type of space this teaching needs
AllocRoundId	| INTEGER		|FK(AllocRound.id)	| Whether allocation completed

</details>

<details><summary>SubjectEquipment</summary>
<small> (Equipment that the Subject needs) </small>

Column				|	Datatype	|	Keys				|	Description
:-----				|	:----		|	------				|	------
<u>subjectId</u>	| INTEGER		| PK, FK(subject.id)	| Subject
<u>equipmentId</u>	| INTEGER		| PK, FK(equipment.id)	| Equipment (e.g. a musical instrument)
priority			| INTEGER		|						| Importance or rarity of the equipment. (Higher number higher need)
obligatory			| BOOLEAN		|						| Whether equipment obligatory for Subject (Elevates priority) ***NOT IN USE YET 2023-01-01***

</details>

<details><summary>User</summary>

Column			| Datatype		| Keys		    | Description
:-----			| :----			| ------		| ------
<u>id</u>		| INTEGER		| PK			|
email			| VARCHAR(255)	|				|
isAdmin			| BOOLEAN		|				| Whether user has admin rights
passwordHash		| VARCHAR(255)	|				| user passwordHash
isPlanner		| BOOLEAN   	|				| Whether user has planner rights
isStatist		| BOOLEAN   	|				| Whether user has statist rights

</details>

<details><summary>log_event</summary>
Log entry

Column			| Datatype		| Keys		    | Description
:-----			| :----			| ------		| ------
<u>id</u>       | INTEGER       | PK            | log entry id
log_id          | INTEGER       |               | log id
stage           | VARCHAR(255)  |               | (e.g. prioritization phase in allocation)
status          | VARCHAR(255)  |               | e.g. OK or Error
information     | VARCHAR(16000)|               | additional information
created_at      | TIMESTAMP     |               | Creation time

</details>

<details><summary>log_type</summary>

Log type, at the moment (2023-01-01) the only one is allocation log
Column			| Datatype		| Keys		    | Description
:-----			| :----			| ------		| ------
<u>id</u>		| INTEGER		|  PK			|
name			| VARCHAR(255)	| 				| name

</details>

<details>
<summary>log_list</summary>

List of log entries, to find easier e.g. an allocation done at certain time.
Column			| Datatype		| Keys		    | Description
:-----			| :----			| ------		| ------
<u>id</u>       | INTEGER       | PK            |
log_type        | INTEGER      	| FK            | Log type (e.g allocation)
created_at      | TIMESTAMP    	|               | Log entry creation time
</details>
