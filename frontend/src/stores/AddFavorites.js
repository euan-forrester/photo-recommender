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
    async getGroupInfo({ commit }, { groupId, numPhotos } ) {
      const results = await Promise.all([FlickrRepository.getGroupInfo(groupId), FlickrRepository.getGroupPhotos(groupId, numPhotos)]);

      const partialGroupInfo = results[0];
      const groupPhotos = results[1];

      const groupInfo = {
        ...partialGroupInfo,
        groupPhotos,
      };

      commit('setGroupInfo', { groupId, groupInfo });
    },
  },
};
