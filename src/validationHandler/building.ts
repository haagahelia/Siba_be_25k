import {
  createIdValidatorChain,
  createValidator,
  validateDescription,
  validateIdObl,
  validateMultiDescription,
  validateMultiNameObl,
  validateNameObl,
} from './index.js';

// export middleware functions
export const validateBuildingPost = createValidator([
  ...validateNameObl,
  ...validateDescription,
]);

export const validateBuildingPut = createValidator([
  ...validateNameObl,
  ...validateDescription,
  ...validateIdObl,
]);

// This is a bit different as body can have multiple objects,
// => MultiPost!!!
export const validateBuildingMultiPost = createValidator([
  ...validateMultiNameObl,
  ...validateMultiDescription,
]);

export const validateBuildingId = createValidator([
  ...createIdValidatorChain('buildingId'),
]);
