import repository from './repository';

const resource = '/users';

export default {
  getRecommendations(userId) {
    return repository.get(`${resource}/${userId}/recommendations`);
  },
};
