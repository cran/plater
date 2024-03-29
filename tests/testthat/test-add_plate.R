for (i in c(6, 12, 24, 48, 96, 384, 1536)) {
   path <- paste0("testData/", i, "/")
   ################################################################################
   context("testing add_plate-add_plate()")
   ################################################################################
   n_letters <- ifelse(i <= 12, i, 24)
   
   test_that("add_plate works for complete valid data", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
   
      result <- add_plate(complete, filename, "wells")
      expect_that(result$values, is_identical_to(get_well_ids(i)))
      expect_that(result$values, is_identical_to(result$wells))
   })
   
   test_that("add_plate works with reversed file and data arguments but gives warning", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      expect_warning({
         result <- add_plate(filename, complete, "wells")
         expect_that(result$values, is_identical_to(get_well_ids(i)))
         expect_that(result$values, is_identical_to(result$wells))         
      }, "reversed")
   })
   
   test_that("add_plate works without leading zeroes", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids_without_leading_zeroes(i), 
         d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      expect_that(result$wells, 
         is_identical_to(get_well_ids_without_leading_zeroes(i)))
      expect_that(remove_leading_zeroes(result$values), is_identical_to(result$wells))
   })
   
   test_that("add_plate works for missing data from plate", {
      filename <- paste0(path, "wellIdsAndEmptyWells.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      
      expect_that(result$wells, is_identical_to(get_well_ids(i)))
      r <- is.na(result$values) | result$values == as.character(result$wells)
      expect_true(all(r))
   })
   
   test_that(paste("add_plate works for missing data from",
         "plate and no leading zeroes"), {
      filename <- paste0(path, "wellIdsAndEmptyWells.csv")
      complete <- data.frame(wells = get_well_ids_without_leading_zeroes(i), 
         d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      
      expect_that(result$wells, 
         is_identical_to(get_well_ids_without_leading_zeroes(i)))
      result$values <- remove_leading_zeroes(result$values)
      r <- is.na(result$values) | result$values == as.character(result$wells)
      expect_true(all(r))
   })
   
   test_that("add_plate works when plate layout contains wells missing from data and gets order right (rows missing from data at end)", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete[2:i, ], filename, "wells")
      
      # missing row from data = well A01, so should be added at end by add_plate
      expected <- rbind(complete[2:i, ], data.frame(wells = "A01", d = NA, stringsAsFactors = FALSE))
      expected$values <- expected$wells
      
      expect_that(result, is_equivalent_to(expected))
   })
   
   test_that(paste("add_plate stops if some wells are missing",
      "leading zeroes and some aren't"), {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)

      set.seed(10)
      complete$wells <- ifelse(rnorm(i) < 0, 
         remove_leading_zeroes(complete$wells), 
         complete$wells)
      
      expect_that(add_plate(complete, filename, "wells"), throws_error())
   })
   
   test_that("add_plate works with one full plate and one partially empty", {
      filename <- paste0(path, "oneFullOnePartEmpty.csv")
      
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters],
         stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      expect_that(result$full, is_identical_to(get_well_ids(i)))
      expect_that(result$full, is_identical_to(result$wells))
      r <- is.na(result$partial) | result$partial == as.character(result$wells)
      expect_true(all(r))
   })
   
   test_that("add_plate works for complete valid data", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      expect_is(result, "tbl_df")
   })
   
   test_that("add_plate works for plate with single element with full plate df", {
      filename <- paste0(path, "oneWell.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      
      expect_that(result$wells, is_identical_to(get_well_ids(i)))
      r <- is.na(result$values) | result$values == "singleton"
      expect_true(all(r))
   })
   
   test_that("add_plate works for plate with single element with single well df", {
      filename <- paste0(path, "oneWell.csv")
      complete <- data.frame(wells = "A01", d = "A", stringsAsFactors = FALSE)
      
      result <- add_plate(complete, filename, "wells")
      
      expect_that(result$wells, is_identical_to("A01"))
      expect_that(result$values, is_identical_to("singleton"))
   })
      
   ################################################################################
   context("testing add_plate-wrong_wells_error_message()")
   ################################################################################
   test_that("wrong_wells_error_message returns correct message with 1 well missing", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      annotations <- read_plate(filename, "wellIds")
      annotations <- annotations[!(is.na(annotations$values)), ]
      
      message <- wrong_wells_error_message(complete[1:(i-1), ], "wells", annotations)
      missing <- get_well_ids(i)[i] # get last well
      expected <- paste0("Some wells in your file are not in the data frame ",
         "you provided, but they all should be. The missing wells are: ", 
         missing, ".")
      expect_that(message, is_identical_to(expected))
   })
   
   test_that("wrong_wells_error_message returns correct message with 2 wells missing", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      annotations <- read_plate(filename, "wellIds")
      annotations <- annotations[!(is.na(annotations$values)), ]
      
      message <- wrong_wells_error_message(complete[1:(i-2), ], "wells", annotations)
      missing <- get_well_ids(i)[(i-1):i] # get last two wells
      missing <- paste0(missing, collapse = ", ")
      expected <- paste0("Some wells in your file are not in the data frame ",
         "you provided, but they all should be. The missing wells are: ", 
         missing, ".")
      expect_that(message, is_identical_to(expected))
   })
   
   test_that("wrong_wells_error_message returns correct message with all but 1 well missing", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      
      annotations <- read_plate(filename, "wellIds")
      annotations <- annotations[!(is.na(annotations$values)), ]
      
      message <- wrong_wells_error_message(complete[1, ], "wells", annotations)
      missing <- get_well_ids(i)[-1] # get all but first
      missing <- paste0(missing, collapse = ", ")
      expected <- paste0("Some wells in your file are not in the data frame ",
         "you provided, but they all should be. The missing wells are: ", 
         missing, ".")
      expect_that(message, is_identical_to(expected))
   })
   
   test_that("wrong_wells_error_message errors with valid input", {
      filename <- paste0(path, "allWellIds.csv")
      complete <- data.frame(wells = get_well_ids(i), d = letters[1:n_letters], stringsAsFactors = FALSE)
      complete$d <- as.character(complete$d)
      
      annotations <- read_plate(filename, "wellIds")
      annotations <- annotations[!(is.na(annotations$values)), ]
      
      expect_that(wrong_wells_error_message(complete, "wells", annotations), 
         throws_error())
   })
}