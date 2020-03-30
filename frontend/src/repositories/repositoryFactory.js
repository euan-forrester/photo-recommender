import flickrRepository from './flickrRepository';
import usersRepository from './usersRepository';

const repositories = {
  flickr: flickrRepository,
  users: usersRepository,
};

export default {
  get: (name) => repositories[name],
};
