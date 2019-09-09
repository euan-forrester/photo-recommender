import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');
const UsersRepository = RepositoryFactory.get('users');

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default {
  state: {
    recommendations: [],
    personInfo: {},
  },
  mutations: {
    setRecommendations(state, recommendations) {
      state.recommendations = recommendations;
    },
    setPersonInfo(state, { userId, personInfo }) {
      state.personInfo[userId] = personInfo;
    },
  },
  actions: {
    async getRecommendationsForUser({ commit }, { userId, numPhotos, numUsers }) {
      const recommendations = await UsersRepository.getRecommendations(userId, numPhotos, numUsers);

      commit('setRecommendations', recommendations.data);
    },
    async getPersonInfo({ commit }, userId) {
      const personInfo = await FlickrRepository.getPersonInfo(userId);

      commit('setPersonInfo', { userId, personInfo });
    },
  },
};
