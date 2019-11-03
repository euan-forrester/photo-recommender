import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  state: {
    groupInfo: {},
  },
  mutations: {
    setGroupInfo(state, { groupId, groupInfo }) {
      state.groupInfo[groupId] = groupInfo;
    },
  },
  actions: {
    async getGroupInfo({ commit }, groupId) {
      const results = await Promise.all([FlickrRepository.getGroupInfo(groupId), FlickrRepository.getGroupPhotos(groupId, numPhotos)]);

      const groupInfo = results[0];
      const groupPhotos = results[1];

      const combinedGroupInfo = {
        ...groupInfo,
        photos: groupPhotos,
      };

      commit('setGroupInfo', { userId, combinedGroupInfo });
    },
  },
};
