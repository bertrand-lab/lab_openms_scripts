library(magrittr)
library(dplyr)


filter_for_targets <- function(quant_out_pep){
  
  # function for filtering peptide targets. this assumes that your input has a 'peptide'
  # column, which is the output from OpenMS ProteinQuantifier.
  
  # first make an empty dataframe
  pep_characteristic_df <- data.frame(between_8_and_21 = logical(),
                                      no_dibasic = logical(),
                                      no_missed_cleav = logical(),
                                      less_than_three_c = logical(),
                                      no_meth = logical(),
                                      no_hist = logical(),
                                      peptide = character())
  
  # go through all the rows of your OpenMS output
  for(row_i in 1:nrow(quant_out_pep)){
    
    #apply the rules
    peptide_i <- quant_out_pep[row_i, ]$peptide %>% as.character()
    trimmed_peptide_i <- substr(x = peptide_i, start = 2, stop = nchar(peptide_i))
    
    between_8_and_21_i <- ifelse(test = nchar(peptide_i) > 8,
                                 yes = 1,
                                 no = 0)
    no_dibasic_i <- ifelse(test = !grepl(pattern = "KK|RR|KR", 
                                         x = peptide_i),
                           yes = 1,
                           no = 0)
    no_miss_cleav_i <- ifelse(test = grepl(pattern = "K|R", 
                                           x = trimmed_peptide_i),
                              yes = 1,
                              no = 0)
    less_than_three_c_i <- ifelse(test = str_count(peptide_i, fixed("C")) < 3, 
                                  yes = 1,
                                  no = 0)
    no_meth_i = ifelse(test = str_count(peptide_i, fixed("M")) == 0,
                       yes = 1,
                       no = 0)
    no_hist_i = ifelse(test = str_count(peptide_i, fixed("H")) == 0,
                       yes = 1,
                       no = 0)
    
    ## append these to the df
    pep_characteristic_df_i <- data.frame(between_8_and_21 = between_8_and_21_i,
                                          no_dibasic = no_dibasic_i,
                                          no_missed_cleav = no_miss_cleav_i,
                                          less_than_three_c = less_than_three_c_i,
                                          no_meth = no_meth_i,
                                          no_hist = no_hist_i,
                                          peptide = peptide_i)
    pep_characteristic_df <- rbind(pep_characteristic_df, 
                                   pep_characteristic_df_i)
    
  }
  # get an aggregate score for the peptides, where each of these rules correspond to 
  # one 'point'
  pep_char_mut <- pep_characteristic_df %>% 
    mutate(pep_choice_score = between_8_and_21 + no_dibasic + no_missed_cleav + less_than_three_c + no_meth + no_hist)
  
  return(pep_char_mut)
}