// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');

module.exports = {
  devServer: {
    proxy: {
      '/api': {
        target: 'http://localhost:4445',
      },
    },
  },

  pluginOptions: {
    s3Deploy: {
      registry: undefined,
      awsProfile: 'default',
      region: 'us-west-2',
      bucket: 'photo-recommender-dev',
      createBucket: false,
      staticHosting: true,
      staticIndexPage: 'index.html',
      staticErrorPage: 'index.html',
      assetPath: 'dist',
      assetMatch: '**',
      deployPath: '/',
      acl: 'public-read',
      pwa: false,
      enableCloudfront: false, // Invalidates a CloudFront distribution
      cloudfrontId: 'E156TT79QZCNSR',
      uploadConcurrency: 5,
      pluginVersion: '3.0.0',
    },
  },

  // configureWebpack: {
  //  plugins: [new BundleAnalyzerPlugin()]
  // }
};
