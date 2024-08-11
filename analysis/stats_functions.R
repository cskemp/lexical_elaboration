# This R file contains the frequentist and Bayesian statistical analysis functions.

# Functions used for the frequentist analyses on seven case studies:

run_glmmTMB <- function(groupname, dstats, predictor_name) {

  # Filter the dataset
  dstats_this <- dstats %>%
    filter(group == .env$groupname) %>%
    drop_na(propn)

  # Define formulas for models
  formula_full <- as.formula(paste("cbind(propn, dictsize_data - propn) ~", predictor_name, "+ (1|area) + (1|langfamily) + (1|glottocode)"))
  formula_reduced <- as.formula("cbind(propn, dictsize_data - propn) ~ (1|area) + (1|langfamily) + (1|glottocode)")
  formula_full_noarea <- as.formula(paste("cbind(propn, dictsize_data - propn) ~", predictor_name, "+ (1|langfamily) + (1|glottocode)"))
  formula_reduced_noarea <- as.formula("cbind(propn, dictsize_data - propn) ~ (1|langfamily) + (1|glottocode)")

  # Initialize list to store warnings
  warnings_list <- list()

  # Function to capture warnings
  capture_warnings <- function(expr) {
    warnings <- NULL
    result <- withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    list(result = result, warnings = warnings)
  }

  # Fit full model
  full_model <- capture_warnings(glmmTMB(formula_full, data = dstats_this, family = binomial))
  m1 <- full_model$result
  warnings_list$m1 <- full_model$warnings

  # Fit reduced model
  reduced_model <- capture_warnings(glmmTMB(formula_reduced, data = dstats_this, family = binomial))
  m2 <- reduced_model$result
  warnings_list$m2 <- reduced_model$warnings

  # Perform ANOVA
  a <- anova(m2, m1)
  pval <- a$`Pr(>Chisq)`[2]

  # Fit full model without area
  full_model_noarea <- capture_warnings(glmmTMB(formula_full_noarea, data = dstats_this, family = binomial))
  m1_a <- full_model_noarea$result
  warnings_list$m1_a <- full_model_noarea$warnings

  # Fit reduced model without area
  reduced_model_noarea <- capture_warnings(glmmTMB(formula_reduced_noarea, data = dstats_this, family = binomial))
  m2_a <- reduced_model_noarea$result
  warnings_list$m2_a <- reduced_model_noarea$warnings

  # Perform ANOVA
  a_a <- anova(m2_a, m1_a)
  pval_a <- a_a$`Pr(>Chisq)`[2]

  # Retrieve coefficients
  if (predictor_name == "subsistence") {
    envcoef <- fixef(m1)$cond["subsistenceother"]
    envcoef_a <- fixef(m1_a)$cond["subsistenceother"]
  } else {
    envcoef <- fixef(m1)$cond[paste(predictor_name)]
    envcoef_a <- fixef(m1_a)$cond[paste(predictor_name)]
  }

  # Summarize results
  summ <- tibble(
    group = groupname,
    predictor = predictor_name,
    coefficient = envcoef,
    p_val = pval,
    coefficient_noarea = envcoef_a,
    p_val_noarea = pval_a,
    warnings_m1 = list(warnings_list$m1),
    warnings_m2 = list(warnings_list$m2),
    warnings_m1_a = list(warnings_list$m1_a),
    warnings_m2_a = list(warnings_list$m2_a)
  )

  summ$warnings_m1 <- sapply(summ$warnings_m1, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2 <- sapply(summ$warnings_m2, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m1_a <- sapply(summ$warnings_m1_a, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2_a <- sapply(summ$warnings_m2_a, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")

  return(summ)
}


run_glmmTMB_withdict <- function(groupname, dstats, predictor_name) {

  # Filter the dataset
  dstats_this <- dstats %>%
    filter(group == .env$groupname) %>%
    drop_na(propn)

  # Define formulas for models
  formula_full <- as.formula(paste("cbind(propn, dictsize_data - propn) ~", predictor_name, "+ (1|id) + (1|area) + (1|langfamily) + (1|glottocode)"))
  formula_reduced <- as.formula("cbind(propn, dictsize_data - propn) ~ (1|id) + (1|area) + (1|langfamily) + (1|glottocode)")
  formula_full_noarea <- as.formula(paste("cbind(propn, dictsize_data - propn) ~", predictor_name, "+ (1|id) + (1|langfamily) + (1|glottocode)"))
  formula_reduced_noarea <- as.formula("cbind(propn, dictsize_data - propn) ~ (1|id) + (1|langfamily) + (1|glottocode)")

  # Initialize list to store warnings
  warnings_list <- list()

  # Function to capture warnings
  capture_warnings <- function(expr) {
    warnings <- NULL
    result <- withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    list(result = result, warnings = warnings)
  }

  # Fit full model
  full_model <- capture_warnings(glmmTMB(formula_full, data = dstats_this, family = binomial))
  m1 <- full_model$result
  warnings_list$m1 <- full_model$warnings

  # Fit reduced model
  reduced_model <- capture_warnings(glmmTMB(formula_reduced, data = dstats_this, family = binomial))
  m2 <- reduced_model$result
  warnings_list$m2 <- reduced_model$warnings

  # Perform ANOVA
  a <- anova(m2, m1)
  pval <- a$`Pr(>Chisq)`[2]

  # Fit full model without area
  full_model_noarea <- capture_warnings(glmmTMB(formula_full_noarea, data = dstats_this, family = binomial))
  m1_a <- full_model_noarea$result
  warnings_list$m1_a <- full_model_noarea$warnings

  # Fit reduced model without area
  reduced_model_noarea <- capture_warnings(glmmTMB(formula_reduced_noarea, data = dstats_this, family = binomial))
  m2_a <- reduced_model_noarea$result
  warnings_list$m2_a <- reduced_model_noarea$warnings

  # Perform ANOVA
  a_a <- anova(m2_a, m1_a)
  pval_a <- a_a$`Pr(>Chisq)`[2]

  # Retrieve coefficients
  if (predictor_name == "subsistence") {
    envcoef <- fixef(m1)$cond["subsistenceother"]
    envcoef_a <- fixef(m1_a)$cond["subsistenceother"]
  } else {
    envcoef <- fixef(m1)$cond[paste(predictor_name)]
    envcoef_a <- fixef(m1_a)$cond[paste(predictor_name)]
  }

  # Summarize results
  summ <- tibble(
    group = groupname,
    predictor = predictor_name,
    coefficient = envcoef,
    p_val = pval,
    coefficient_noarea = envcoef_a,
    p_val_noarea = pval_a,
    warnings_m1 = list(warnings_list$m1),
    warnings_m2 = list(warnings_list$m2),
    warnings_m1_a = list(warnings_list$m1_a),
    warnings_m2_a = list(warnings_list$m2_a)
  )

  summ$warnings_m1 <- sapply(summ$warnings_m1, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2 <- sapply(summ$warnings_m2, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m1_a <- sapply(summ$warnings_m1_a, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2_a <- sapply(summ$warnings_m2_a, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")

  return(summ)
}

# Functions used for Bayesian analyses on seven case studies:

run_bayes <- function(groupname, dstats, predictorname) {

  dstats_this <- dstats %>%
    filter(group == .env$groupname) %>%
    drop_na(propn)

  formula <- paste0("propn | trials(dictsize_data) ~ ", predictorname, "+ (1|id) + (1|langfamily) + (1|glottocode)")

  mdl <- quiet_brm(formula, data = dstats_this, family = "binomial",
                   iter = myiter, chains = 2, control = mycontrol)

  m <- mdl$result

  envcoef <- fixef(m)[2]
  lci <- fixef(m)[6]
  uci <- fixef(m)[8]

  summ <- tibble(
    group = groupname,
    predictor = predictorname,
    coefficient = envcoef,
    lower_ci = lci,
    upper_ci = uci,
    warnings = paste(mdl$warnings, collapse = " | ")
  )

  return(summ)
}


run_bayes_area <- function(groupname, dstats, predictorname) {

  dstats_this <- dstats %>%
    filter(group == .env$groupname) %>%
    drop_na(propn)

  formula <- paste0("propn | trials(dictsize_data) ~ ", predictorname, "+ (1|id) + (1|area) + (1|langfamily) + (1|glottocode)")

  mdl <- quiet_brm(formula, data = dstats_this, family = "binomial",
                   iter = myiter, chains = mychains, control = mycontrol)
  m <- mdl$result

  envcoef <- fixef(m)[2]
  lci <- fixef(m)[6]
  uci <- fixef(m)[8]

  summ <- tibble(
    group = groupname,
    predictor = predictorname,
    coefficient = envcoef,
    lower_ci = lci,
    upper_ci = uci,
    warnings = paste(mdl$warnings, collapse = " | ")
  )

  return(summ)
}


run_bayes_area_simple <- function(groupname, dstats, predictorname) {

  dstats_this <- dstats %>%
    filter(group == .env$groupname) %>%
    drop_na(propn)

  formula <- paste0("propn | trials(dictsize_data) ~ ", predictorname, "+ (1|area) + (1|langfamily) + (1|glottocode)")

  mdl <- quiet_brm(formula, data = dstats_this, family = "binomial",
                   iter = myiter, chains = mychains, control = mycontrol)
  m <- mdl$result

  envcoef <- fixef(m)[2]
  lci <- fixef(m)[6]
  uci <- fixef(m)[8]

  summ <- tibble(
    group = groupname,
    predictor = predictorname,
    coefficient = envcoef,
    lower_ci = lci,
    upper_ci = uci,
    warnings = paste(mdl$warnings, collapse = " | ")
  )

  return(summ)
}

# Functions used for bottom-up analyses:

run_glmmTMB_dict <- function(word, dstats, predictor_name) {

  # Filter the dataset
  dstats_this <- dstats %>%
    filter(word == .env$word) %>%
    drop_na(count)

  # Define formulas for models
  formula_full <- as.formula(paste("cbind(count, dictsize_data - count) ~", predictor_name, "+ (1|id) + (1|glottocode) + (1|langfamily)"))
  formula_reduced <- as.formula("cbind(count, dictsize_data - count) ~ (1|id) + (1|glottocode) + (1|langfamily)")

  # Initialize list to store warnings
  warnings_list <- list()

  # Function to capture warnings
  capture_warnings <- function(expr) {
    warnings <- NULL
    result <- withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    list(result = result, warnings = warnings)
  }

  # Fit full model
  full_model <- capture_warnings(glmmTMB(formula_full, data = dstats_this, family = binomial))
  m1 <- full_model$result
  warnings_list$m1 <- full_model$warnings

  # Fit reduced model
  reduced_model <- capture_warnings(glmmTMB(formula_reduced, data = dstats_this, family = binomial))
  m2 <- reduced_model$result
  warnings_list$m2 <- reduced_model$warnings

  # Perform ANOVA
  a <- anova(m2, m1)
  pval <- a$`Pr(>Chisq)`[2]

  # Retrieve coefficients
  if (predictor_name == "subsistence") {
    envcoef <- fixef(m1)$cond["subsistenceother"]
  } else {
    envcoef <- fixef(m1)$cond[paste(predictor_name)]
  }

  # Summarize results
  summ <- tibble(
    word = word,
    predictor = predictor_name,
    coefficient = envcoef,
    p_val = pval,
    warnings_m1 = list(warnings_list$m1),
    warnings_m2 = list(warnings_list$m2)
  )

  summ$warnings_m1 <- sapply(summ$warnings_m1, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2 <- sapply(summ$warnings_m2, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")

  return(summ)
}


run_glmmTMB_dictarea <- function(word, dstats, predictor_name) {

  # Filter the dataset
  dstats_this <- dstats %>%
    filter(word == .env$word) %>%
    drop_na(count)

  # Define formulas for models
  formula_full <- as.formula(paste("cbind(count, dictsize_data - count) ~", predictor_name, "+ (1|id) + (1|glottocode) + (1|langfamily) + (1|area)"))
  formula_reduced <- as.formula("cbind(count, dictsize_data - count) ~ (1|id) + (1|glottocode) + (1|langfamily) + (1|area)")

  # Initialize list to store warnings
  warnings_list <- list()

  # Function to capture warnings
  capture_warnings <- function(expr) {
    warnings <- NULL
    result <- withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    list(result = result, warnings = warnings)
  }

  # Fit full model
  full_model <- capture_warnings(glmmTMB(formula_full, data = dstats_this, family = binomial))
  m1 <- full_model$result
  warnings_list$m1 <- full_model$warnings

  # Fit reduced model
  reduced_model <- capture_warnings(glmmTMB(formula_reduced, data = dstats_this, family = binomial))
  m2 <- reduced_model$result
  warnings_list$m2 <- reduced_model$warnings

  # Perform ANOVA
  a <- anova(m2, m1)
  pval <- a$`Pr(>Chisq)`[2]

  # Retrieve coefficients
  if (predictor_name == "subsistence") {
    envcoef <- fixef(m1)$cond["subsistenceother"]
  } else {
    envcoef <- fixef(m1)$cond[paste(predictor_name)]
  }

  # Summarize results
  summ <- tibble(
    word = word,
    predictor = predictor_name,
    coefficient = envcoef,
    p_val = pval,
    warnings_m1 = list(warnings_list$m1),
    warnings_m2 = list(warnings_list$m2)
  )

  summ$warnings_m1 <- sapply(summ$warnings_m1, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")
  summ$warnings_m2 <- sapply(summ$warnings_m2, function(x) if (length(x) > 0) paste(x, collapse = ";") else "")

  return(summ)
}
