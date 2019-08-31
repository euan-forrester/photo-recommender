<template>
  <div>
    {{ this.$route.params.userId }}
    <Recommendation imageId="5987578841" imageOwner="88859707@N00" imageUrl="https://live.staticflickr.com/6018/5987578841_6863d519bb_b.jpg"/>
  </div>
</template>

<script>

import Recommendation from '../components/Recommendation.vue';

export default {
  components: {
    Recommendation,
  },
};
</script>
