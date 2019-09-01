import Vue from 'vue';
import Vuex from 'vuex';

import RepositoryFactory from './repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');
const UsersRepository = RepositoryFactory.get('users');

Vue.use(Vuex);

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default new Vuex.Store({
  state: {
    user: {
      id: '',
      name: '',
      recommendations: [],
      currentlyProcessingData: false,
      haveInitiallyProcessedData: false,
    },
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
    setRecommendations(state, recommendations) {
      state.user.recommendations = recommendations;
    },
    setProcessingStatus(state, { currentlyProcessingData, haveInitiallyProcessedData }) {
      state.user.currentlyProcessingData = currentlyProcessingData;
      state.user.haveInitiallyProcessedData = haveInitiallyProcessedData;
    },
  },
  actions: {
    async getUserIdFromUrl({ commit }, userUrl) {
      const response = await FlickrRepository.getUserIdFromUrl(userUrl);

      const user = {
        id: response.data.user.id,
        name: response.data.user.username._content, // eslint-disable-line no-underscore-dangle
        recommendations: [],
        currentlyProcessingData: false,
        haveInitiallyProcessedData: false,
      };

      commit('setUser', user);
    },
    async getRecommendationsForUser({ commit }, { userId, numPhotos }) {
      const recommendations = await UsersRepository.getRecommendations(userId, numPhotos);

      commit('setRecommendations', recommendations.data);
    },
    async addNewUser({ commit }, userId) {
      const userInfo = await UsersRepository.addUser(userId);

      commit('setProcessingStatus', {
        currentlyProcessingData: userInfo.data.currently_processing_data,
        haveInitiallyProcessedData: userInfo.data.have_initially_processed_data,
      });
    },
    async getUserInfo({ commit }, userId) {
      const userInfo = await UsersRepository.getUser(userId);

      commit('setProcessingStatus', {
        currentlyProcessingData: userInfo.data.currently_processing_data,
        haveInitiallyProcessedData: userInfo.data.have_initially_processed_data,
      });
    },
  },
});
