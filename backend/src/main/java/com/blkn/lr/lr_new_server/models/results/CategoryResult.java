package com.blkn.lr.lr_new_server.models.results;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CategoryResult {
    String name;
    Double finalScore;

    List<SubCategoryResult> subResults;
}
