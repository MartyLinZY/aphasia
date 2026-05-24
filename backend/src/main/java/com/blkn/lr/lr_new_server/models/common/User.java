package com.blkn.lr.lr_new_server.models.common;

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
    int role;

}
