import flickrRepository from './flickrRepository';

const repositories = {
  flickr: flickrRepository,
};

export default {
  get: name => repositories[name],
};
