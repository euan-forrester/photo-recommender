class Output:

    @staticmethod
    def get_output(photo_recommendations):

        output = ""

        output += "<h1>Photos you may like</h1>\n"

        for recommendation in photo_recommendations:
            output += f"<a href=https://www.flickr.com/photos/{recommendation.get_image_owner()}/{recommendation.get_image_id()}/><img src={recommendation.get_image_url()}/></a><br/>\n"

        return output