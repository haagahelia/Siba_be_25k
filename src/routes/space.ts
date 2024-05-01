import express, { Request, Response } from 'express';
import knex from 'knex';
import { admin } from '../authorization/admin.js';
import { planner } from '../authorization/planner.js';
import { roleChecker } from '../authorization/roleChecker.js';
import { statist } from '../authorization/statist.js';
import { authenticator } from '../authorization/userValidation.js';
import db from '../db/index.js';
import db_knex from '../db/index_knex.js';
import {
  dbErrorHandler,
  requestErrorHandler,
  successHandler,
} from '../responseHandler/index.js';
import { Space } from '../types/custom.js';
import logger from '../utils/logger.js';
import { validate, validateIdObl } from '../validationHandler/index.js';
import {
  validateMultiSpacePost,
  validateSpacePut,
} from '../validationHandler/space.js';

const space = express.Router();

// Get all spaces
space.get(
  '/',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex
      .select(
        's.id',
        's.name',
        's.area',
        's.info',
        's.personLimit',
        's.buildingId',
        db_knex.raw('TIME_FORMAT(s.availableFrom,"%H:%i") as "availableFrom"'),
        db_knex.raw('TIME_FORMAT(s.availableTo,"%H:%i") as "availableTo"'),
        db_knex.raw('TIME_FORMAT(s.classesFrom,"%H:%i") as "classesFrom"'),
        db_knex.raw('TIME_FORMAT(s.classesTo,"%H:%i") as "classesTo"'),
        's.inUse',
        's.spaceTypeId',
        'b.name AS buildingName',
        'st.name AS spaceTypeName',
        'st.acronym AS spaceTypeAcronym',
      )
      .from('Space as s')
      .innerJoin('Building as b', 's.buildingId', 'b.id')
      .leftJoin('SpaceType as st', 's.spaceTypeId', 'st.id')
      .then((spaces) => {
        successHandler(req, res, spaces, 'getAll successful - Space');
      })
      .catch((err) => {
        requestErrorHandler(
          req,
          res,
          `Oops! Nothing came through - Space: ${err.message}`,
        );
      });
  },
);

// SPECIAL Listing all the spaces for selection dropdown etc.
// (Just name and id) using knex
space.get(
  '/getNames',
  [authenticator, admin, roleChecker],
  (req: Request, res: Response) => {
    db_knex
      .select('id', 'name')
      .from('Space')
      .then((spaceNames) => {
        successHandler(req, res, spaceNames, 'getNames successful - Space');
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Nothing came through - Space');
      });
  },
);

// SPECIAL list all space name with building name
space.get(
  '/NameInBuilding',
  [authenticator, admin, roleChecker],
  (req: Request, res: Response) => {
    db_knex('Space')
      .select(db_knex.raw('CONCAT(Space.name, "-", Building.name) as name'))
      .join('Building', 'Space.buildingId', '=', 'Building.id')
      .then((spaceNames) => {
        successHandler(req, res, spaceNames, 'getNames successful - Space');
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Nothing came through - Space');
      });
  },
);

space.get(
  '/:id',
  validateIdObl,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const id = req.params.id;
    db_knex('Space')
      .select(
        's.id',
        's.name',
        's.area',
        's.info',
        's.personLimit',
        's.buildingId',
        db_knex.raw('TIME_FORMAT(s.availableFrom,"%H:%i") as "availableFrom"'),
        db_knex.raw('TIME_FORMAT(s.availableTo,"%H:%i") as "availableTo"'),
        db_knex.raw('TIME_FORMAT(s.classesFrom,"%H:%i") as "classesFrom"'),
        db_knex.raw('TIME_FORMAT(s.classesTo,"%H:%i") as "classesTo"'),
        's.inUse',
        's.spaceTypeId',
        'b.name AS buildingName',
        'st.name AS spaceTypeName',
        'st.acronym AS spaceTypeAcronym',
      )
      .from('Space as s')
      .innerJoin('Building as b', 's.buildingId', 'b.id')
      .leftJoin('SpaceType as st', 's.spaceTypeId', 'st.id')
      .where('s.id', id)
      .then((spaces) => {
        if (spaces.length === 1) {
          successHandler(
            req,
            res,
            spaces,
            'get space by id successful - Space',
          );
        } else {
          requestErrorHandler(req, res, `No space found with id ${id}`);
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'DB prob while trying get space by id');
      });
  },
);

// Adding a space
space.post(
  '/',
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    const spaceData = {
      name: req.body.name,
      area: req.body.area,
      info: req.body.info,
      personLimit: req.body.personLimit,
      buildingId: req.body.buildingId,
      availableFrom: req.body.availableFrom,
      availableTo: req.body.availableTo,
      classesFrom: req.body.classesFrom,
      classesTo: req.body.classesTo,
      inUse: req.body.inUse, //  || true, // Default to true if not provided
      spaceTypeId: req.body.spaceTypeId,
    };

    db_knex('Space')
      .insert(spaceData)
      .then((result) => {
        if (result.length === 0) {
          requestErrorHandler(req, res, 'Nothing to insert');
        } else {
          successHandler(
            req,
            res,
            { insertId: result[0] }, // Assuming auto-incremented ID
            'Space created successfully.',
          );
        }
      })
      .catch((error) => {
        requestErrorHandler(
          req,
          res,
          `Oops! Create failed - Space: ${error.message}`,
        );
      });
  },
);

// Adding multiple subjects/teachings using knex
space.post(
  '/multi',
  validateMultiSpacePost,
  [authenticator, admin, planner, roleChecker, validate],
  async (req: Request, res: Response) => {
    console.log(req.body);
    const spaceData: Space[] = [];

    for (const space of req.body) {
      const [building] = await db_knex('Building')
        .select('id')
        .where('name', space.buildingName);
      const [spaceType] = await db_knex('SpaceType')
        .select('id')
        .where('name', space.spaceType);

      if (!building || !space) {
        return !building
          ? requestErrorHandler(
              req,
              res,
              `'Program ${building.buildingName} not found`,
            )
          : requestErrorHandler(
              req,
              res,
              `Space ${building.spaceType} not found`,
            );
      }

      spaceData.push({
        name: space.name,
        area: space.area,
        info: space.info,
        personLimit: space.personLimit,
        buildingId: building.id,
        availableFrom: space.availableFrom,
        availableTo: space.availableTo,
        classesFrom: space.classesFrom,
        classesTo: space.classesTo,
        inUse: space.inUse,
        spaceTypeId: spaceType.id,
      });
    }

    console.log(spaceData);

    db_knex('Space')
      .insert(spaceData)
      .then((result) => {
        if (result.length === 0) {
          requestErrorHandler(req, res, 'Nothing to insert');
        } else {
          successHandler(
            req,
            res,
            { insertId: result }, // Assuming auto-incremented ID
            'Create successful - Spaces',
          );
          logger.info('Spaces created');
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Create failed - Spaces');
      });
  },
);

// Delete space by id
space.delete(
  '/:id',
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Space')
      .where('id', req.params.id)
      .del()
      .then((rowsAffected) => {
        if (rowsAffected === 1) {
          successHandler(
            req,
            res,
            rowsAffected,
            `Delete successful! Count of deleted rows: ${rowsAffected}`,
          );
        } else {
          requestErrorHandler(req, res, `Invalid space ID: ${req.params.id}`);
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Delete failed - Space');
      });
  },
);

// Update space
space.put(
  '/',
  validateSpacePut,
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    const spaceId = req.body.id;
    const updatedSpaceData = {
      name: req.body.name,
      area: req.body.area,
      info: req.body.info,
      personLimit: req.body.personLimit,
      buildingId: req.body.buildingId,
      availableFrom: req.body.availableFrom,
      availableTo: req.body.availableTo,
      classesFrom: req.body.classesFrom,
      classesTo: req.body.classesTo,
      inUse: req.body.inUse, // || true, // Default to true if not provided
      spaceTypeId: req.body.spaceTypeId,
    };

    db_knex('Space')
      .where('id', spaceId)
      .update(updatedSpaceData)
      .then((rowsAffected) => {
        if (rowsAffected === 1) {
          successHandler(
            req,
            res,
            rowsAffected,
            `Update successful! Count of modified rows: ${rowsAffected}`,
          );
        } else {
          requestErrorHandler(req, res, `Invalid space ID: ${spaceId}`);
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Update failed - Space');
      });
  },
);

//Allow fetching spaces by a specific building ID.
space.get(
  '/byBuilding/:buildingId',
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    const { buildingId } = req.params;
    db_knex('Space')
      .where({ buildingId })
      .then((spaces) => {
        if (spaces.length > 0) {
          successHandler(
            req,
            res,
            spaces,
            `Spaces found for building ID: ${buildingId}`,
          );
        } else {
          successHandler(
            req,
            res,
            [],
            `No spaces found for building ID: ${buildingId}`,
          );
        }
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to fetch spaces by building ID',
        );
      });
  },
);

//Allow fetching spaces by a specific SpaceType ID.
space.get(
  '/bySpaceType/:spaceTypeId',
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    const { spaceTypeId } = req.params;
    db_knex('Space')
      .where({ spaceTypeId })
      .then((spaces) => {
        if (spaces.length > 0) {
          successHandler(
            req,
            res,
            spaces,
            `Spaces found for space type ID: ${spaceTypeId}`,
          );
        } else {
          successHandler(
            req,
            res,
            [],
            `No spaces found for space type ID: ${spaceTypeId}`,
          );
        }
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to fetch spaces by space type ID',
        );
      });
  },
);

// fetching total no. of allocations associated with space by space id
space.get(
  '/:id/numberOfAllocSpaces',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const spaceId = req.params.id;
    db_knex('AllocSpace')
      .countDistinct('allocRoundId as count')
      .where('spaceId', spaceId)
      .then((allocRoundId) => {
        successHandler(
          req,
          res,
          allocRoundId,
          'Successfully recived the total number of allocspace by space id from database',
        );
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to get the total number of allocspace by space id from database',
        );
      });
  },
);

//fetching allocation rounds associated with space by id
space.get(
  '/:id/allocRoundsAssociatedWithSpace',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const spaceId = req.params.id;
    db_knex('AllocSpace')
      .join('AllocRound', 'AllocSpace.allocRoundId', 'AllocRound.id')
      .distinct('AllocRound.name')
      .where('AllocSpace.spaceId', spaceId)
      .limit(5)
      .then((allocRoundNames) => {
        successHandler(
          req,
          res,
          allocRoundNames,
          'Successfully recived the allocRounds associated with space by ID',
        );
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to get the allocRounds associated with space by ID from database',
        );
      });
  },
);
export default space;
