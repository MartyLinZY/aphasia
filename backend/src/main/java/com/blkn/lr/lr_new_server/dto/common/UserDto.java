package com.blkn.lr.lr_new_server.dto.common;

import com.blkn.lr.lr_new_server.models.common.User;
import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserDto {
    String identity;
    String password;
    String uid;
    String token;
    int role;

    public UserDto(User user) {
        identity = user.getIdentity();
        uid = user.getId();
        role = user.getRole();
    }
}
