import {
  createIdValidatorChain,
  createMultiNameValidatorChain,
  validateIdObl,
  validateMultiNameObl,
  validateNameObl,
} from './index.js';

export const validateProgramId = [...createIdValidatorChain('programId')];

// this needs to continue
export const validateProgramPost = [
  ...validateNameObl,
  ...createIdValidatorChain('departmentId'),
];

export const validateProgramPut = [...validateProgramPost, ...validateIdObl];

export const validateProgramMultiPost = [
  ...validateMultiNameObl,
  ...createMultiNameValidatorChain('department'),
];
