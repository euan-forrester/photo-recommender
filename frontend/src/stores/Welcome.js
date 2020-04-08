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
      numNeighbors: 0,
      numFavorites: 0,
      numPullerRequestsMade: 0,
      numPullerRequestsFinished: 0,
      numIngesterRequestsMade: 0,
      numIngesterRequestsFinished: 0,
      processingStatusIsDirty: true, // If true, then the above numbers are not reflective of the state of the database
    },
  },
  getters: {
    // A request isn't completely finished until it's both been pulled from the external API and
    // ingested into our database, so pick the minimum here.
    numRequestsCompleted: (state) => Math.min(
      state.user.numPullerRequestsFinished,
      state.user.numIngesterRequestsFinished,
    ),
    // These 2 numbers should be the same (we have a one-to-one mapping of puller requests to
    // ingester requests), but pick the max just to be safe.
    numRequestsMade: (state) => Math.max(
      state.user.numPullerRequestsMade,
      state.user.numIngesterRequestsMade,
    ),
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
    setProcessingStatus(state,
      {
        currentlyProcessingData, haveInitiallyProcessedData, numNeighbors, numFavorites,
        numPullerRequestsMade, numPullerRequestsFinished, numIngesterRequestsMade, numIngesterRequestsFinished,
      }) {
      state.user.currentlyProcessingData = currentlyProcessingData;
      state.user.haveInitiallyProcessedData = haveInitiallyProcessedData;
      state.user.numNeighbors = numNeighbors;
      state.user.numFavorites = numFavorites;
      state.user.numPullerRequestsMade = numPullerRequestsMade;
      state.user.numPullerRequestsFinished = numPullerRequestsFinished;
      state.user.numIngesterRequestsMade = numIngesterRequestsMade;
      state.user.numIngesterRequestsFinished = numIngesterRequestsFinished;
      state.user.processingStatusIsDirty = false;
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
        numNeighbors: 0,
        numFavorites: 0,
        numPullerRequestsMade: 0,
        numPullerRequestsFinished: 0,
        numIngesterRequestsMade: 0,
        numIngesterRequestsFinished: 0,
        processingStatusIsDirty: true,
      };

      commit('setUser', user);
    },
    async getUserIdCurrentlyLoggedIn({ commit }) {
      const userResponse = await FlickrRepository.getCurrentlyLoggedInUser();

      const user = {
        id: userResponse.id,
        name: userResponse.name,
        recommendations: [],
        currentlyProcessingData: false,
        haveInitiallyProcessedData: false,
        numNeighbors: 0,
        numFavorites: 0,
        numPullerRequestsMade: 0,
        numPullerRequestsFinished: 0,
        numIngesterRequestsMade: 0,
        numIngesterRequestsFinished: 0,
        processingStatusIsDirty: true,
      };

      commit('setUser', user);
    },
    async addNewUser({ commit }, userId) {
      const userInfo = await UsersRepository.addUser(userId);

      commit('setProcessingStatus', {
        currentlyProcessingData: userInfo.data.currently_processing_data,
        haveInitiallyProcessedData: userInfo.data.have_initially_processed_data,
        numNeighbors: userInfo.data.num_neighbors,
        numFavorites: userInfo.data.num_favorites,
        numPullerRequestsMade: userInfo.data.num_puller_requests_made,
        numPullerRequestsFinished: userInfo.data.num_puller_requests_finished,
        numIngesterRequestsMade: userInfo.data.num_ingester_requests_made,
        numIngesterRequestsFinished: userInfo.data.num_ingester_requests_finished,
      });
    },
    async getUserInfo({ commit }, userId) {
      const userInfo = await UsersRepository.getUser(userId);

      commit('setProcessingStatus', {
        currentlyProcessingData: userInfo.data.currently_processing_data,
        haveInitiallyProcessedData: userInfo.data.have_initially_processed_data,
        numNeighbors: userInfo.data.num_neighbors,
        numFavorites: userInfo.data.num_favorites,
        numPullerRequestsMade: userInfo.data.num_puller_requests_made,
        numPullerRequestsFinished: userInfo.data.num_puller_requests_finished,
        numIngesterRequestsMade: userInfo.data.num_ingester_requests_made,
        numIngesterRequestsFinished: userInfo.data.num_ingester_requests_finished,
      });
    },
  },
};
