import repository from './repository';

const resource = '/users';

export default {
  getRecommendations(userId, numPhotos) {
    return repository.get(`${resource}/${userId}/recommendations`, { params: { 'num-photos': numPhotos } });
  },
};
