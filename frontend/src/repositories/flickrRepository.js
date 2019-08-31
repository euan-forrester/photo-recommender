import repository from './repository';

const resource = '/flickr';

export default {
  getUserIdFromUrl(userUrl) {
    return repository.get(`${resource}/urls/lookup-user`, { params: { url: userUrl } });
  },
};
