import express, { Request, Response } from 'express';
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
import { ProgramWithDepartmentId } from '../types/custom.js';
import logger from '../utils/logger.js';
import { validate, validateIdObl } from '../validationHandler/index.js';
import {
  validateProgramMultiPost,
  validateProgramPost,
  validateProgramPut,
} from '../validationHandler/program.js';
import { validateProgramId } from '../validationHandler/program.js';
import { validateUserId } from '../validationHandler/user.js';

const program = express.Router();

// Program id:s and name:s, to be used in a select list
/*program.get(
  '/',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex
      .select('id', 'name')
      .from('Program')
      .then((programs) => {
        successHandler(req, res, programs, 'getNames successful - Program');
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Nothing came through - Program');
      });
  },
);*/
program.get(
  '/',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex
      .select(
        'p.id',
        'p.name',
        'p.departmentId',
        'd.name AS departmentName', // Include department name
      )
      .from('Program as p')
      .innerJoin('Department as d', 'p.departmentId', 'd.id') // Join with Department table
      .then((programs) => {
        successHandler(req, res, programs, 'getAll successful - Program');
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Nothing came through - Program');
      });
  },
);

// get program by id
program.get(
  '/:id',
  validateIdObl,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex
      .select()
      .from('Program')
      .where('id', req.params.id)
      .then((data) => {
        successHandler(
          req,
          res,
          data,
          `Successfully read the program from DB with id: ${req.params.id}`,
        );
      })
      .catch((err) => {
        dbErrorHandler(req, res, err, 'Oops! Nothing came through - Program');
      });
  },
);

// get program by programName and email
program.get(
  '/programName/:email',
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Program')
      .select('Program.name')
      .join(
        'DepartmentPlanner',
        'Program.departmentId',
        '=',
        'DepartmentPlanner.departmentId',
      )
      .join('User', 'DepartmentPlanner.userId', '=', 'User.id')
      .where('User.email', '=', req.params.email)
      .then((data) => {
        successHandler(
          req,
          res,
          data,
          `Succesfully read the program from DB with user email: ${req.params.email} `,
        );
      })
      .catch((err) => {
        dbErrorHandler(req, res, err, 'Oops! Nothing came through - Program');
      });
  },
);

//get for a single user's associated programs ids
program.get(
  '/userprograms/:userId',
  validateUserId,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex('Program')
      .select('Program.id')
      .join('Department', 'Department.id', 'Program.departmentId')
      .join(
        'DepartmentPlanner',
        'DepartmentPlanner.departmentId',
        'Department.id',
      )
      .join('User', 'User.id', 'DepartmentPlanner.userId')
      .where('User.id', req.params.userId)
      .then((data) => {
        successHandler(
          req,
          res,
          data,
          `Succesfully fetched programs from DB with user: ${req.params.userId} `,
        );
      })
      .catch((err) => {
        dbErrorHandler(req, res, err, 'Oops! Nothing came through - Program');
      });
  },
);

// create program
// TODO: add validationHandler for validating program name and departmentId
program.post(
  '/',
  validateProgramPost,
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    const newProgram = {
      name: req.body.name,
      departmentId: req.body.departmentId,
    };

    db_knex('Program')
      .insert(newProgram)
      .returning('id') //  auto-incremented ID
      .then((result) => {
        const insertedId = result[0];

        successHandler(
          req,
          res,
          { id: insertedId },
          'Create successful - Program',
        );
        logger.info(`Program ${newProgram.name} created with ID ${insertedId}`);
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Create failed - Program');
      });
  },
);

program.post(
  '/multi',
  validateProgramMultiPost,
  [authenticator, admin, planner, roleChecker, validate],
  async (req: Request, res: Response) => {
    console.log(req.body);
    const programData: ProgramWithDepartmentId[] = [];

    for (const program of req.body) {
      const [department] = await db_knex('Department')
        .select('id')
        .where('name', program.department);

      if (!department) {
        return requestErrorHandler(
          req,
          res,
          `'Program ${department.departmentName} not found`,
        );
      }

      programData.push({
        name: program.name,
        departmentId: department.id,
      });
    }

    console.log(programData);

    db_knex('Program')
      .insert(programData)
      .then((result) => {
        if (result.length === 0) {
          requestErrorHandler(req, res, 'Nothing to insert');
        } else {
          successHandler(
            req,
            res,
            { insertId: result }, // Assuming auto-incremented ID
            'Create successful - Programs',
          );
          logger.info('Programs created');
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Create failed - Programs');
      });
  },
);

// edit program by id
program.put(
  '/',
  validateProgramPut,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    const id = req.body.id;
    const name = req.body.name;
    const departmentId = req.body.departmentId;

    db_knex('Program')
      .where('id', id)
      .update({ name, departmentId })
      .then((result) => {
        if (result === 0) {
          requestErrorHandler(
            req,
            res,
            `Nothing to update for Program with ID ${id}`,
          );
        } else {
          successHandler(req, res, result, 'Update successful - Program');
          logger.info(`Program ${name} updated`);
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Update failed - Program');
      });
  },
);

// delete a program with id
program.delete(
  '/:id',
  validateIdObl,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    const id = req.params.id;

    db_knex('Program')
      .where('id', id)
      .del()
      .then((result) => {
        if (result === 0) {
          requestErrorHandler(
            req,
            res,
            `Nothing to delete for Program with ID ${id}`,
          );
        } else {
          successHandler(req, res, result, 'Delete successful - Program');
          logger.info('Program deleted');
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Delete failed - Program');
      });
  },
);
//fetch number of lessons from the selected program
program.get(
  '/:programId/numberOfLessons',
  validateProgramId,
  [authenticator, admin, planner, statist, roleChecker, validate],
  (req: Request, res: Response) => {
    const programId = req.params.programId;

    db_knex('Subject')
      .count('*')
      .where('Subject.programId', programId)
      .first()
      .then((numberOfLessons) => {
        successHandler(
          req,
          res,
          numberOfLessons,
          'Successfully retrieved the number of lessons for the program',
        );
      })
      .catch((error) => {
        dbErrorHandler(
          req,
          res,
          error,
          'Failed to retrieve the number of lessons for the program',
        );
      });
  },
);

export default program;
