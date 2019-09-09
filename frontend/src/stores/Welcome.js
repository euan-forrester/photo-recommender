import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');
const UsersRepository = RepositoryFactory.get('users');

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default {
  state: {
    user: {
      id: '',
      name: '',
      currentlyProcessingData: false,
      haveInitiallyProcessedData: false,
    },
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
    setProcessingStatus(state, { currentlyProcessingData, haveInitiallyProcessedData }) {
      state.user.currentlyProcessingData = currentlyProcessingData;
      state.user.haveInitiallyProcessedData = haveInitiallyProcessedData;
    },
  },
  actions: {
    async getUserIdFromUrl({ commit }, userUrl) {
      const userResponse = await FlickrRepository.getUserIdFromUrl(userUrl);

      const user = {
        id: userResponse.id,
        name: userResponse.name,
        recommendations: [],
        currentlyProcessingData: false,
        haveInitiallyProcessedData: false,
      };

      commit('setUser', user);
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
};
