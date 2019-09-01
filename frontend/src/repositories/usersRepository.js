import repository from './repository';

const resource = '/users';

export default {
  getRecommendations(userId, numPhotos) {
    return repository.get(`${resource}/${userId}/recommendations`, { params: { 'num-photos': numPhotos } });
  },
  addUser(userId) {
    return repository.post(`${resource}/${userId}`);
  },
  deleteUser(userId) {
    return repository.delete(`${resource}/${userId}`);
  },
  getUser(userId) {
    return repository.get(`${resource}/${userId}`);
  },
};
