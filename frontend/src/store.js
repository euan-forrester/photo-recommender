import Vue from 'vue';
import Vuex from 'vuex';

import WelcomeModule from './stores/Welcome';
import RecommendationsModule from './stores/Recommendations';

Vue.use(Vuex);

// See https://medium.com/js-dojo/vuex-tip-error-handling-on-actions-ee286ed28df4 for an explanation of how error handling here works

export default new Vuex.Store({
  modules: {
    welcome: WelcomeModule,
    recommendations: RecommendationsModule,
  },
});
