package com.example.server.helper;

import org.junit.Assert;
import org.junit.Test;

public class UtilTest {

    @Test
    public void parseUserIdFromConsumingRk() {
        // setup
        String userReceivingQueueRkPattern = "rk_user_receive_queue_%s_%s";
        String mockUserId = "foo-bar-baz";
        String mockSalt = "1234567890";
        String encodedString = String.format(userReceivingQueueRkPattern, mockUserId, mockSalt);

        // execute
        String userId = Util.parseUserIdFromConsumingRk(encodedString);

        // assert
        Assert.assertEquals(mockUserId, userId);
    }
}
