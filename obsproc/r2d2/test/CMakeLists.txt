execute_process( COMMAND ${CMAKE_COMMAND} -E create_symlink
           ${CMAKE_CURRENT_SOURCE_DIR}/obs-2-move
           ${CMAKE_CURRENT_BINARY_DIR}/obs-2-move )
execute_process( COMMAND ${CMAKE_COMMAND} -E copy
           ${CMAKE_CURRENT_SOURCE_DIR}/../src/r2d2_config.yaml
           ${CMAKE_CURRENT_BINARY_DIR}/r2d2_config.yaml )

add_test ( emc_obsdb0 ${CMAKE_CURRENT_SOURCE_DIR}/../test/test.sh )
