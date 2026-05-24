package com.blkn.lr.lr_new_server.dto.common;

import com.blkn.lr.lr_new_server.models.common.User;
import com.fasterxml.jackson.annotation.JsonInclude;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class UserDto {
    @NotBlank(message = "identity不能为空")
    String identity;

    @NotBlank(message = "password不能为空")
    String password;

    String uid;
    String token;

    @Min(value = 1, message = "role必须为1或2")
    @Max(value = 2, message = "role必须为1或2")
    int role;

    public UserDto(User user) {
        identity = user.getIdentity();
        uid = user.getId();
        role = user.getRole();
    }
}
