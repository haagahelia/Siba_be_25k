import express, { Request, Response } from 'express';
import { MysqlError } from 'mysql';
import { admin } from '../authorization/admin.js';
import { planner } from '../authorization/planner.js';
import { roleChecker } from '../authorization/roleChecker.js';
import { statist } from '../authorization/statist.js';
import { authenticator } from '../authorization/userValidation.js';
import db_knex from '../db/index_knex.js';
import {
  dbErrorHandler,
  requestErrorHandler,
  successHandler,
} from '../responseHandler/index.js';
import {
  validateBuildingMultiPost,
  validateBuildingPost,
  validateBuildingPut,
} from '../validationHandler/building.js';
import { validateBuildingId } from '../validationHandler/building.js';
import { validate, validateIdObl } from '../validationHandler/index.js';

const building = express.Router();

function handleErrorBasedOnErrno(
  req: Request,
  res: Response,
  error: MysqlError,
  defaultMessage: string,
) {
  switch (error.errno) {
    case 1062:
      requestErrorHandler(
        req,
        res,
        `Conflict: Building with the name ${req.body.name} already exists!`,
      );
      break;
    case 1054:
      requestErrorHandler(
        req,
        res,
        "error in spelling [either in 'name' and/or in 'description'].",
      );
      break;
    default:
      dbErrorHandler(req, res, error, defaultMessage);
      break;
  }
}

// get all buildings   GET server.com:4678/api/building/
building.get(
  '/',
  [authenticator, admin, statist, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Building')
      .select()
      .then((data) => {
        successHandler(
          req,
          res,
          data,
          'Successfully read the buildings from DB',
        );
      })
      .catch((err) => {
        dbErrorHandler(
          req,
          res,
          err,
          'Error trying to read all buildings from DB',
        );
      });
  },
);

// get building by id  server.com:4678/api/building/101
building.get(
  '/:id',
  validateIdObl,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Building')
      .select()
      .where('id', req.params.id)
      .then((data) => {
        if (data.length === 1) {
          successHandler(
            req,
            res,
            data,
            'Successfully read the building from DB',
          );
        } else {
          requestErrorHandler(
            req,
            res,
            `Failed to fetch building from DB with id: ${req.params.id}`,
          );
        }
      })
      .catch((err) => {
        dbErrorHandler(req, res, err, 'Oops! Nothing came through - Building');
      });
  },
);

// adding single building
building.post(
  '/',
  validateBuildingPost,
  [authenticator, admin, roleChecker],
  (req: Request, res: Response) => {
    db_knex('Building')
      .insert(req.body)
      .into('Building')
      .then((idArray) => {
        successHandler(
          req,
          res,
          idArray,
          'Adding a building, or multiple buildings was successful',
        );
      })
      .catch((error) => {
        handleErrorBasedOnErrno(req, res, error, 'error adding building');
      });
  },
);

// adding single or multiple building
building.post(
  '/multi',
  validateBuildingMultiPost,
  [authenticator, admin, roleChecker],
  (req: Request, res: Response) => {
    db_knex('Building')
      .insert(req.body)
      .into('Building')
      .then((idArray) => {
        successHandler(
          req,
          res,
          idArray,
          'Adding a building, or multiple buildings was succesful',
        );
      })
      .catch((error) => {
        handleErrorBasedOnErrno(req, res, error, 'error adding building');
      });
  },
);

// updating building information
building.put(
  '/',
  validateBuildingPut,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    if (!req.body.name) {
      requestErrorHandler(req, res, 'Building name is missing.');
    } else {
      db_knex('Building')
        .where('id', req.body.id)
        .update(req.body)
        .then((rowsAffected) => {
          if (rowsAffected === 1) {
            successHandler(
              req,
              res,
              rowsAffected,
              `Update building successful! Count of modified rows: ${rowsAffected}`,
            );
          } else {
            requestErrorHandler(
              req,
              res,
              `Update building not successful, ${rowsAffected} row modified`,
            );
          }
        })
        .catch((error) => {
          handleErrorBasedOnErrno(req, res, error, 'error updating building');
        });
    }
  },
);

// delete building by id => DELETE  /api/building/301
building.delete(
  '/:id',
  validateIdObl,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Building')
      .select()
      .where('id', req.params.id)
      .del()
      .then((rowsAffected) => {
        if (rowsAffected === 1) {
          successHandler(
            req,
            res,
            rowsAffected,
            `Delete succesfull! Count of deleted rows: ${rowsAffected}`,
          );
        } else {
          requestErrorHandler(req, res, `Invalid building id:${req.params.id}`);
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Error deleting building');
      });
  },
);

//fetch number of spaces from the selected buildings
building.get(
  '/:buildingId/numberOfSpaces',
  validateBuildingId,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const buildingId = req.params.buildingId;

    db_knex('Space')
      .count('*')
      .where('Space.buildingId', buildingId)
      .first()
      .then((numberOfSpaces) => {
        successHandler(
          req,
          res,
          numberOfSpaces,
          'Successfully retrieved the number of spaces for the building',
        );
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to retrieve the number of spaces for the building',
        );
      });
  },
);

// Count the number of spaces associated with a specific building ID
building.get(
  '/spaceCount/:id',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const { id } = req.params;
    db_knex('Space')
      .count('* as count')
      .where('buildingId', id)
      .then(([result]) => {
        successHandler(
          req,
          res,
          result,
          'Successfully counted spaces for the building',
        );
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to count spaces for the building',
        );
      });
  },
);

export default building;
