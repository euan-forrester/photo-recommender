import repository from './repository';
import vueAuth from '../auth';

// Our API server proxies certain requests to Flickr, and returns results in whatever format that Flickr defines.
// The only exception is that our API server will return a 404 if the item isn't found, rather than how
// Flickr handles its error codes.
//
// So this file contains the knowledge of how to call Flickr via our API, and how to decode its responses.

const resource = '/flickr';

const getProfileUrl = (userId) => `https://www.flickr.com/photos/${userId}/`;

export default {
  async getUserIdFromUrl(userUrl) {
    const response = await repository.get(`${resource}/urls/lookup-user`, { params: { url: userUrl } });

    return {
      id: response.data.user.id,
      name: response.data.user.username._content, // eslint-disable-line no-underscore-dangle
    };
  },
  async getPersonInfo(userId) {
    const response = await repository.get(`${resource}/people/get-info`, { params: { 'user-id': userId } });

    // 'realname' may not be defined, or it may be defined and contains an empty string.
    // Either way, we want to default to their username instead

    let realName = 'realname' in response.data.person ? response.data.person.realname._content : ''; // eslint-disable-line no-underscore-dangle

    if (realName.length === 0) {
      realName = response.data.person.username._content; // eslint-disable-line no-underscore-dangle
    }

    const iconFarm = response.data.person.iconfarm;
    const iconServer = response.data.person.iconserver;
    const nsId = response.data.person.nsid;

    // Construct a link to their buddy icon according to these rules: https://www.flickr.com/services/api/misc.buddyicons.html
    let iconUrl = 'https://www.flickr.com/images/buddyicon.gif';

    if (iconServer > 0) {
      iconUrl = `https://farm${iconFarm}.staticflickr.com/${iconServer}/buddyicons/${nsId}.jpg`;
    }

    const profileUrl = getProfileUrl(nsId);

    return {
      userId,
      realName,
      iconUrl,
      profileUrl,
    };
  },
  async addComment(photoId, commentText) {
    await repository.post(
      `${resource}/photos/add-comment`,
      { 'oauth-token': vueAuth.getToken(), 'comment-text': commentText },
      { params: { 'photo-id': photoId } },
    );
  },
  async addFavorite(imageId, imageOwner, imageUrl) {
    await repository.post(
      `${resource}/favorites/add`,
      {
        'oauth-token': vueAuth.getToken(),
        'image-id': imageId,
        'image-owner': imageOwner,
        'image-url': imageUrl,
      },
    );
  },
  async getCurrentlyLoggedInUser() {
    const response = await repository.post(
      `${resource}/test/login`,
      { 'oauth-token': vueAuth.getToken() },
    );

    return {
      id: response.data.user.id,
      name: response.data.user.username._content, // eslint-disable-line no-underscore-dangle
    };
  },
  async logoutUser() {
    await repository.post(
      `${resource}/auth/logout`,
      { 'oauth-token': vueAuth.getToken() },
    );
  },
  getPhotoUrl(imageOwner, imageId) {
    return `https://www.flickr.com/photos/${imageOwner}/${imageId}`;
  },
  getProfileUrl(userId) {
    return getProfileUrl(userId);
  },
};
