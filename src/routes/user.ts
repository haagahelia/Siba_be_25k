import bcrypt from 'bcrypt';
import dotenv from 'dotenv';
import express, { Request, Response } from 'express';
import jsonwebtoken from 'jsonwebtoken';
import { admin } from '../authorization/admin.js';
import { planner } from '../authorization/planner.js';
import { roleChecker } from '../authorization/roleChecker.js';
import { authenticator } from '../authorization/userValidation.js';
import db_knex from '../db/index_knex.js';
import {
  authenticationErrorHandler,
  dbErrorHandler,
  requestErrorHandler,
  successHandler,
} from '../responseHandler/index.js';
import { DepartmentPlanner } from '../types/custom.js';
import logger from '../utils/logger.js';
import { validate, validateIdObl } from '../validationHandler/index.js';
import {
  validateMultiUserPost,
  validateUserPost,
  validateUserPut,
} from '../validationHandler/user.js';

dotenv.config({});

const user = express.Router();

// adding user
user.post(
  '/',
  validateUserPost,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    const hashedPassword = bcrypt.hashSync(req.body.password, 10);
    // REMOVE AFTER SOME TESTING!!! SECURITY!!!
    console.log(
      `Register, clear text password from frontend: ${req.body.password}`,
    );
    req.body.password = hashedPassword;
    // REMOVE AFTER SOME TESTING!!! SECURITY!!!
    console.log(`Register, password hashed for DB: ${req.body.password}`);
    db_knex
      .insert(req.body)
      .into('User')
      .then((idArray) => {
        successHandler(req, res, idArray, 'Adding user success');
      })
      .catch((error) => {
        if (error.errno === 1062 || error.errno === 1169) {
          requestErrorHandler(
            req,
            res,
            `User with that email ${req.body.email} already exists`,
          );
        } else {
          dbErrorHandler(req, res, error, 'Some DB error while adding user');
        }
      });
  },
);

// add multiple users
user.post(
  '/multi',
  validateMultiUserPost,
  [authenticator, admin, roleChecker, validate],
  async (req: Request, res: Response) => {
    const userDepartmentPlanner: DepartmentPlanner[] = [];
    // insert user data
    for (const userData of req.body) {
      // securing password
      const hashedPassword = bcrypt.hashSync(userData.password, 10);
      userData.password = hashedPassword;
      // inserting user data
      const [userID] = await db_knex('User').insert({
        email: userData.email,
        password: userData.password,
        isAdmin: userData.isAdmin,
        isPlanner: userData.isPlanner,
        isStatist: userData.isStatist,
      });
      // get user id of inserted users
      const [getUserId] = await db_knex('User')
        .select('id')
        .where('email', userData.email);

      /// Split department names
      const departmentNames: string[] = userData.department
        ? userData.department.split('|')
        : [];

      // If departmentNames is empty, skip adding to userDepartmentPlanner
      if (departmentNames.length > 0) {
        for (const departmentName of departmentNames) {
          const [getDeptId] = await db_knex('Department')
            .select('id')
            .where('name', departmentName);

          // Push the user ID and department ID into the userDepartmentPlanner array
          userDepartmentPlanner.push({
            userId: getUserId?.id ?? 0,
            departmentId: getDeptId?.id ?? 0,
          });
        }
      }
    }
    // If there are any records in userDepartmentPlanner, attempt to insert them
    if (userDepartmentPlanner.length > 0) {
      db_knex('Departmentplanner')
        .insert(userDepartmentPlanner)
        .then((result) => {
          if (result.length === 0) {
            requestErrorHandler(req, res, 'Nothing to insert');
          } else {
            successHandler(
              req,
              res,
              { insertId: result[0] },
              'Create successful - Subject',
            );
            logger.info(`Department planner ${userDepartmentPlanner} created`);
          }
        })
        .catch((error) => {
          dbErrorHandler(req, res, error, 'Oops! Create failed - Subject');
        });
    } else {
      // If there are no departments specified in any userData, handle it accordingly
      successHandler(req, res, {}, 'Create successful - Subject');
    }
  },
);

// Fetching all users
user.get(
  '/',
  [authenticator, admin, planner, roleChecker, validate],
  (req: Request, res: Response) => {
    db_knex
      .select(
        'u.id',
        'u.email',
        'u.isAdmin',
        'u.isPlanner',
        'u.isStatist',
        db_knex.raw(
          "GROUP_CONCAT(d.name SEPARATOR ' | ') as 'plannerdepartment'",
        ),
      )
      .from('User as u')
      .leftJoin('DepartmentPlanner as dp', 'u.id', 'dp.userid')
      .leftJoin('Department as d', 'dp.departmentid', 'd.id')
      .groupBy('u.id')
      .then((users) => {
        successHandler(req, res, users, 'getAll successful - Users');
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Nothing came through - Users');
      });
  },
);

// handling login for registered user
user.post('/login', (req, res) => {
  console.log(`Login, password: ${req.body.password}`);
  db_knex('User')
    .select('id', 'email', 'password', 'isAdmin', 'isPlanner', 'isStatist')
    .where('email', req.body.email)
    .then((data) => {
      if (data.length === 1) {
        bcrypt
          .compare(req.body.password, data[0].password)
          .then((passwordCheck) => {
            if (!passwordCheck) {
              authenticationErrorHandler(
                req,
                res,
                "/login: Passwords don't match!",
              );
              return;
            } else {
              const token = jsonwebtoken.sign(
                {
                  id: data[0].id,
                  email: data[0].email,
                  isAdmin: data[0].isAdmin,
                  isPlanner: data[0].isPlanner,
                  isStatist: data[0].isStatist,
                },
                process.env.SECRET_TOKEN as string,
                { expiresIn: '24h' },
              );
              const updatedData = data.map((obj) => ({ ...obj, token }));
              successHandler(req, res, updatedData, '/login: Ok');
            }
          })
          .catch((err) => {
            requestErrorHandler(
              req,
              res,
              `${err} /login: Oops! Nothing came through - User`,
            );
          });
      } else {
        authenticationErrorHandler(
          req,
          res,
          `login with email '${req.body.email}' not found`,
        );
      }
    })
    .catch((error) => {
      dbErrorHandler(req, res, error, '/login: Database error');
    });
});

//forget password handling
user.post('/forget-password', (req, res) => {
  const { email } = req.body;
  db_knex('User')
    .select('id', 'email')
    .where('email', email)
    .then((data) => {
      if (data.length === 0) {
        requestErrorHandler(req, res, 'Email not registered yet!');
      } else {
        const token = jsonwebtoken.sign(
          { id: data[0].id, email: email },
          process.env.SECRET_TOKEN as string,
          { expiresIn: '24h' },
        );

        const user = {
          id: data[0].id,
          token: token,
        };

        successHandler(req, res, user, 'Token regenerated successfully');
      }
    })
    .catch((error) => {
      dbErrorHandler(req, res, error, '/forget-password: Database error');
    });
});

//reset password handling
user.post('/reset-password/:id/:token', (req: Request, res: Response) => {
  const { id, token } = req.params;
  const { password } = req.body;

  jsonwebtoken.verify(
    token,
    process.env.SECRET_TOKEN as string,
    (err, decoded) => {
      console.log('decoded: ', decoded);
      if (err) {
        requestErrorHandler(req, res, 'Could not verify token!');
      } else {
        const hashedPassword = bcrypt.hashSync(password, 10);
        db_knex('User')
          .update('password', hashedPassword)
          .where('id', id)
          .then((data) => {
            if (data) {
              successHandler(req, res, data, 'Password reset successful');
            } else {
              requestErrorHandler(req, res, 'Could not reset! Sorry');
            }
          })
          .catch((error) => {
            dbErrorHandler(req, res, error, 'Reset failed!');
          });
      }
    },
  );
});

// Changing userdata
user.put(
  '/',
  validateUserPut,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    const userData = {
      id: req.body.id,
      email: req.body.email,
      isAdmin: req.body.isAdmin,
      isPlanner: req.body.isPlanner,
      isStatist: req.body.isStatist,
    };
    db_knex('User')
      .update(userData)
      .where('id', req.body.id)
      .then((result) => {
        if (!result) {
          requestErrorHandler(req, res, 'Nothing to update');
        } else {
          successHandler(req, res, result, 'Update successful - User');
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! Update failed - User');
      });
  },
);

// Removing a user
user.delete(
  '/:id',
  validateIdObl,
  [authenticator, admin, roleChecker, validate],
  (req: Request, res: Response) => {
    const id = req.params.id;
    db_knex('User')
      .delete()
      .where('id', id)
      .then((result) => {
        if (!result) {
          requestErrorHandler(req, res, 'Nothing to delete');
        } else {
          successHandler(req, res, result, 'Delete successful - User');
        }
      })
      .catch((error) => {
        dbErrorHandler(req, res, error, 'Oops! delete failed - User');
      });
  },
);

export default user;
