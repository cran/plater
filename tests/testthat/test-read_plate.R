for (i in c(6, 12, 24, 48, 96, 384, 1536)) {
   path <- paste0("testData/", i, "/")
   ################################################################################
   context("testing read_plate-read_plate()")
   ################################################################################
   
   test_that("read_plate works for complete valid data", {
      filename <- paste0(path, "allWellIds.csv")
   
      result <- read_plate(filename, "wells")
      expect_that(result$values, is_identical_to(get_well_ids(i)))
      expect_that(result$values, is_identical_to(result$wells))
   })
   
   test_that("read_plate works for missing data from plate", {
      filename <- paste0(path, "wellIdsAndEmptyWells.csv")
      
      result <- read_plate(filename, "wells")
      
      expect_that(result$wells, is_identical_to(result$values))
   })

   test_that("read_plate works with one full plate and one partially empty", {
      filename <- c(paste0(path, "oneFullOnePartEmpty.csv"))
      
      result <- read_plate(filename, "wells")
      expect_that(result$full, is_identical_to(get_well_ids(i)))
      expect_that(result$full, is_identical_to(result$wells))
      r <- is.na(result$partial) | result$partial == as.character(result$wells)
      expect_true(all(r))
   })
   
   test_that("read_plate returns a tbl_df", {
      expect_is(read_plate(paste0(path, "allWellIds.csv")), 
         "tbl_df")
   })
   
   test_that("read_plate allows weird characters", {
      filename <- paste0(path, "weirdCharacters.csv")
      
      result <- read_plate(filename, "wells")
      expect_that(result$values[1:3], is_identical_to(c("#a", "`abc", "~")))
   })
   
   test_that("read_plate works with single well", {
      filename <- paste0(path, "oneWell.csv")
      
      result <- read_plate(filename, "wells")
      
      expect_that(result$values, is_identical_to("singleton"))
   })
   
   ################################################################################
   context("testing read_plate-calculate_number_of_plates()")
   ################################################################################
   makeRawFile <- function(filename) {
      readLines(paste0(path, filename, ".csv"), warn = FALSE)
   }
   
   test_that("calculate_number_of_plates works with one plate no blank row", {
      raw <- makeRawFile("allWellIds")   
      
      result <- calculate_number_of_plates(raw, number_of_rows(i))
      expect_that(result, is_identical_to(1))
   })
   
   test_that("calculate_number_of_plates works with one plate with blank row", {
      raw <- makeRawFile("onePlateOneBlankRow")   
      
      result <- calculate_number_of_plates(raw, number_of_rows(i))
      expect_that(result, is_identical_to(1))
   })
   
   test_that("calculate_number_of_plates fails with one plate with 2 blank rows", {
      raw <- makeRawFile("onePlateTwoBlankRows")   
      
      expect_that(calculate_number_of_plates(raw, number_of_rows(i)), throws_error())
   })
   
   test_that("calculate_number_of_plates works with two plates no blank row", {
      raw <- makeRawFile("twoPlatesNoBlankRow")   
      
      result <- calculate_number_of_plates(raw, number_of_rows(i))
      expect_that(result, is_identical_to(2))
   })
   
   test_that("calculate_number_of_plates works with two plates with blank row", {
      raw <- makeRawFile("twoPlatesOneBlankRow")   
      
      result <- calculate_number_of_plates(raw, number_of_rows(i))
      expect_that(result, is_identical_to(2))
   })
   
   test_that("calculate_number_of_plates fails with two plates with 2 blank rows", {
      raw <- makeRawFile("twoPlatesTwoBlankRows")   
      
      expect_that(calculate_number_of_plates(raw, number_of_rows(i)), throws_error())
   })
}

################################################################################
context("testing read_plate-checkUniquePlateNames()")
################################################################################
   test_that("duplicate plate names get disambiguated", {
      # suppress irrelevant warning about last line of file
      suppressWarnings(
         plate <- read_plate(paste0(path, "twoPlatesNoBlankRow.csv"), "wells") 
      )
      expect_true("values" %in% colnames(plate))
      expect_true("values.2" %in% colnames(plate))
   })
   
   test_that("non-duplicate plate names are unchanged", {
      plate <- read_plate(paste0(path, "oneFullOnePartEmpty.csv"), "wells") 
      
      expect_true("full" %in% colnames(plate))
      expect_true("partial" %in% colnames(plate))
   })
   
   test_that("both empty plate names get filled in and disambiguated", {
      plate <- read_plate(paste0(path, "missingPlateNames.csv"), "wells") 
      
      expect_true("values" %in% colnames(plate))
      expect_true("values.2" %in% colnames(plate))
   })
   
test_that("read_plate doesn't give warning with incomplete final line", {
   filename <- "testData/incomplete-final-line.csv"
   
   # regex = NA means don't expect warnings
   expect_warning(read_plate(filename, "wells"), regex = NA)
})
  
test_that("read_plate handles mixed numbers and strings correctly", {
    # see github issue 18
    filename <- "testData/numbers-and-text.csv"
    
    r <- read_plate(filename)
    expect_that(r$NumbersAndText, is_identical_to(c("text", "1.00E+04", "1.00E+04")))
}) 