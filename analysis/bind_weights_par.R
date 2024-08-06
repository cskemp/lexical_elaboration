# This R file contains logistic regression functions for computing L^lang and L^fam scores.

# compute weights for languages with parallel processing

glmmTMBplus <- function(d) {

  model <- glmmTMB(formula = cbind(count, total - count) ~ (1 | dict), family = binomial, data = d, control = glmmTMBControl(profile=TRUE))

  convergence_status <- if (model$fit$convergence == 0) {
    "converged"
  } else {
    "not converged"
  }

  output <- tidy(model) %>%
    filter(effect == "fixed") %>%
    rename(estimate_set = estimate, se_set = std.error) %>%
    select(estimate_set, se_set) %>%
    mutate(convergence_set = convergence_status)

  return(output)
}

possglmmTMBplus = possibly(.f = glmmTMBplus, otherwise = NULL)

glmmTMBplus_lang <- function(d) {

  model <- glmmTMB(formula = cbind(count, total - count) ~ 0 + lang + (1 | dict), family = binomial, data = d, control = glmmTMBControl(profile=TRUE))

  convergence_status <- if (model$fit$convergence == 0) {
    "converged"
  } else {
    "not converged"
  }

  output <- tidy(model) %>%
    filter(effect == "fixed") %>%
    rename(se = std.error) %>%
    select(term, estimate, se) %>%
    mutate(lang = str_sub(term, start = 5)) %>%
    select(-term) %>%
    mutate(convergence = convergence_status)

  return(output)
}

possglmmTMBplus_lang = possibly(.f = glmmTMBplus_lang, otherwise = NULL)

bind_weights_par <- function(d) {

  no_cores <- (availableCores() - 1) %/% 2
  plan(multicore, workers = no_cores)

  d_nested <- d %>%
    nest(data = c("dict", "lang", "langname", "family", "count", "total"))

  allw_i <- d_nested %>%
    mutate(output= future_map(data, possglmmTMBplus_lang, .progress = TRUE)) %>%
    select(-data) %>%
    unnest(output)

  allw <- d_nested %>%
    mutate(output= future_map(data, possglmmTMBplus, .progress = TRUE)) %>%
    select(-data) %>%
    unnest(output)  %>%
    left_join(allw_i, by = "word") %>%
    mutate(delta = estimate - estimate_set, zeta = delta / sqrt(se^2 + se_set^2) )
}

# compute weights for language families with parallel processing

glmmTMBplus_f <- function(d) {

  model <- glmmTMB(formula = cbind(count, total-count) ~ (1|dict) + (1|lang), family = binomial, data = d, control = glmmTMBControl(profile=TRUE))

  convergence_status <- if (model$fit$convergence == 0) {
    "converged"
  } else {
    "not converged"
  }

  output <- model %>%
    tidy() %>%
    filter(effect == "fixed") %>%
    rename(estimate_set = estimate, se_set = std.error) %>%
    select(estimate_set, se_set) %>%
    mutate(convergence_set = convergence_status)

  return(output)
}

possglmmTMBplus_f = possibly(.f = glmmTMBplus_f, otherwise = NULL)

glmmTMBplus_fam <- function(d) {

  model <- glmmTMB(formula = cbind(count, total-count) ~ 0 + family + (1|dict) + (1|lang), family = binomial, data = d, control = glmmTMBControl(profile=TRUE))

  convergence_status <- if (model$fit$convergence == 0) {
    "converged"
  } else {
    "not converged"
  }

  output <- model %>%
    tidy() %>%
    filter(effect == "fixed") %>%
    rename(se = std.error) %>%
    select(term, estimate, se) %>%
    mutate(family= str_sub(term, start = 7)) %>%
    select(-term)  %>%
    mutate(convergence = convergence_status)

  return(output)
}

possglmmTMBplus_fam = possibly(.f = glmmTMBplus_fam, otherwise = NULL)

bind_weights_fam <- function(d) {

  no_cores <- (availableCores() - 1) %/% 2
  plan(multicore, workers = no_cores)

  d_nested <- d %>%
    nest(data = c("dict", "lang", "langname", "family", "count", "total"))

  allw_i <- d_nested %>%
    mutate(output= future_map(data, possglmmTMBplus_fam, .progress = TRUE)) %>%
    select(-data) %>%
    unnest(output)

  allw <- d_nested %>%
    mutate(output= future_map(data, possglmmTMBplus_f, .progress = TRUE)) %>%
    select(-data) %>%
    unnest(output)  %>%
    left_join(allw_i, by = "word") %>%
    mutate(delta = estimate - estimate_set, zeta = delta / sqrt(se^2 + se_set^2) )
}
