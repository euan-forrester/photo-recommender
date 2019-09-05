import repository from './repository';

const resource = '/flickr';

export default {
  getUserIdFromUrl(userUrl) {
    return repository.get(`${resource}/urls/lookup-user`, { params: { url: userUrl } });
  },
  getPersonInfo(userId) {
    return repository.get(`${resource}/people/get-info`, { params: { 'user-id': userId } });
  },
};
