<template>
  <div>
    <b-link :href="'https://www.flickr.com/photos/' + imageOwner + '/' + imageId">
      <b-img left fluid :src="imageUrl"></b-img>
    </b-link>
  </div>
</template>

<script>
export default {
  props: {
    imageId: String,
    imageOwner: String,
    imageUrl: String,
  },
};
</script>
