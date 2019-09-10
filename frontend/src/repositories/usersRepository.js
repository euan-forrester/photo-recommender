import repository from './repository';

const resource = '/users';

export default {
  getRecommendations(userId, numPhotos, numUsers) {
    return repository.get(`${resource}/${userId}/recommendations`, { params: { 'num-photos': numPhotos, 'num-users': numUsers } });
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
  dismissPhotoRecommendation(userId, dismissedImageId) {
    return repository.put(`${resource}/${userId}/dismiss-photo-recommendation`, null, { params: { 'image-id': dismissedImageId } });
  },
  dismissUserRecommendation(userId, dismissedUserId) {
    return repository.put(`${resource}/${userId}/dismiss-user-recommendation`, null, { params: { 'user-id': dismissedUserId } });
  },
};
