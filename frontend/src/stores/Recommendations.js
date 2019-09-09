import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');
const UsersRepository = RepositoryFactory.get('users');

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default {
  state: {
    recommendations: [],
    personInfo: {},
    dismissedPhotoRecommendations: {},
    dismissedUserRecommendations: {},
  },
  mutations: {
    setRecommendations(state, recommendations) {
      state.recommendations = recommendations;
    },
    setPersonInfo(state, { userId, personInfo }) {
      state.personInfo[userId] = personInfo;
    },
    addDismissedPhotoRecommendation(state, { userId, dismissedImageId }) {
      if (!(userId in state.dismissedPhotoRecommendations)) {
        state.dismissedPhotoRecommendations[userId] = [];
      }

      state.dismissedPhotoRecommendations[userId].push(dismissedImageId);
    },
    addDismissedUserRecommendation(state, { userId, dismissedUserId }) {
      if (!(userId in state.dismissedPhotoRecommendations)) {
        state.dismissedPhotoRecommendations[userId] = [];
      }

      state.dismissedPhotoRecommendations[userId].push(dismissedUserId);
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
    async dismissPhotoRecommendation({ commit }, { userId, dismissedImageId }) {
      await UsersRepository.dismissPhotoRecommendation(userId, dismissedImageId);

      commit('addDismissedPhotoRecommendation', { userId, dismissedImageId });
    },
    async dismissUserRecommendation({ commit }, { userId, dismissedUserId }) {
      await UsersRepository.dismissUserRecommendation(userId, dismissedUserId);

      commit('addDismissedUserRecommendation', { userId, dismissedUserId });
    },
  },
};
