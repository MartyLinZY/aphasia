package com.blkn.lr.lr_new_server.models.common;

import com.blkn.lr.lr_new_server.dto.common.UserDto;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class User {
    String id;
    String identity;
    String password;
    String salt;
    int role;

}
