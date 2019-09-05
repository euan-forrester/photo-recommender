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
    personInfo: {},
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
    setPersonInfo(state, { userId, personInfo }) {
      state.personInfo[userId] = personInfo;
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
    async getPersonInfo({ commit }, userId) {
      const response = await FlickrRepository.getPersonInfo(userId);

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
        iconUrl = `http://farm${iconFarm}.staticflickr.com/${iconServer}/buddyicons/${nsId}.jpg`;
      }

      const profileUrl = `https://www.flickr.com/photos/${nsId}/`;

      const personInfo = {
        userId,
        realName,
        iconUrl,
        profileUrl,
      };

      commit('setPersonInfo', { userId, personInfo });
    },
    async getRecommendationsForUser({ commit }, { userId, numPhotos, numUsers }) {
      const recommendations = await UsersRepository.getRecommendations(userId, numPhotos, numUsers);

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
