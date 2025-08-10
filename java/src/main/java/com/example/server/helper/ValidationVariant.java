package com.example.server.helper;

import com.example.server.model.User;
import java.util.ArrayList;
import lombok.Data;
import lombok.NoArgsConstructor;

@NoArgsConstructor
@Data
public class ValidationVariant {

    User user;
    ArrayList<String> violationMessages;

}
